import math
import torch
import torch.nn as nn
import torch.nn.functional as F
from einops import rearrange, repeat

from typing import Union, List
import torch
from torch import Tensor

class S4D(nn.Module):
    def __init__(self, d_model, d_state=64, dropout=0.0, transposed=True, N=64, dt_min=0.001, dt_max=0.1, lr=None):
        super().__init__()

        self.h = d_model
        self.n = d_state
        self.d_output = self.h
        self.transposed = transposed

        self.D = nn.Parameter(torch.randn(self.h))

        # Generate dt
        log_dt = torch.rand(self.h) * (math.log(dt_max) - math.log(dt_min)) + math.log(dt_min)

        C = torch.randn(self.h, N // 2, dtype=torch.cfloat)
        self.C = nn.Parameter(torch.view_as_real(C))
        self.register("log_dt", log_dt, lr)

        log_A_real = torch.log(0.5 * torch.ones(self.h, N//2))
        A_imag = math.pi * repeat(torch.arange(N//2), pattern='n -> h n', h=self.h)
        self.register("log_A_real", log_A_real, lr)
        self.register("A_imag", A_imag, lr)

        self.activation = nn.GELU()
        dropout_fn = nn.Dropout2d # NOTE: bugged in PyTorch 1.11
        dropout_fn = DropoutNd
        self.dropout = dropout_fn(dropout) if dropout > 0.0 else nn.Identity()

        # position-wise output transform to mix features
        self.output_linear = nn.Sequential(
            nn.Conv1d(self.h, 2*self.h, kernel_size=1),
            nn.GLU(dim=-2),
        )

    def forward(self, u: Tensor): # absorbs return_output and transformer src mask
        """ Input and output shape (B, H, L) """
        if not self.transposed: u = u.transpose(-1, -2)
        L = u.size(-1)

        # S4D Kernel
        # Materialize parameters
        dt = torch.exp(self.log_dt) # (H)
        
        # ### Modified
        
        # # Vandermonde multiplication
        # Extract real and imaginary parts of A
        A_real = -torch.exp(self.log_A_real)
        A_imag = self.A_imag
        
        dtA_real = A_real * dt.unsqueeze(-1)  # (H N)
        dtA_imag = A_imag * dt.unsqueeze(-1)  # (H N)
        
        K_real = dtA_real.unsqueeze(-1) * torch.arange(L, device=A_real.device) # (H N L)
        K_imag = dtA_imag.unsqueeze(-1) * torch.arange(L, device=A_imag.device) # (H N L)
        
        C_real = self.C[..., 0]  # Extract the real part
        C_imag = self.C[..., 1]  # Extract the imaginary part

        # Now perform element-wise operations without explicitly creating complex numbers
        C_real = C_real * (torch.exp(dtA_real) - 1.) / A_real
        C_imag = C_imag * (torch.exp(dtA_imag) - 1.) / A_imag

        # Compute real and imaginary parts of K separately
        K_real = torch.einsum('hn, hnl -> hl', C_real, torch.exp(K_real)).real
        # K_imag = torch.einsum('hn, hnl -> hl', C_imag, torch.exp(K_imag))
        
        # Convolution
        k_f = torch.fft.rfft(K_real, n=2*L) # (H L)
        u_f = torch.fft.rfft(u, n=2*L) # (B H L)
        y = torch.fft.irfft(u_f*k_f, n=2*L)[..., :L] # (B H L)
        
        return y, None

        # Convolution
        k_f_real = torch.fft.rfft(K_real, n=2*L)  # (H L)
        k_f_imag = torch.fft.rfft(K_imag, n=2*L)  # (H L)
        u_f = torch.fft.rfft(u, n=2*L)  # (B H L)

        # Element-wise multiplication in the frequency domain for real and imaginary parts separately
        prod_f_real = u_f[..., None] * k_f_real  # (B H L)
        prod_f_imag = u_f[..., None] * k_f_imag  # (B H L)

        # Inverse FFT and truncation for real and imaginary parts separately
        y_real = torch.fft.irfft(prod_f_real, n=2*L)[..., :L]  # (B H L)
        y_imag = torch.fft.irfft(prod_f_imag, n=2*L)[..., :L]  # (B H L)
        
        return y_real, y_imag
        
        # y = torch.stack((y_real, y_imag), dim=-1)
        
        ### Modified

        C_real = self.C[..., 0]  # Extract the real part
        C_imag = self.C[..., 1]  # Extract the imaginary part
        C = torch.complex(C_real, C_imag)  # Construct complex numbers

        A = -torch.exp(self.log_A_real) + 1j * self.A_imag # (H N)

        # Vandermonde multiplication
        dtA = A * dt.unsqueeze(-1)  # (H N)
        K = dtA.unsqueeze(-1) * torch.arange(L, device=A.device) # (H N L)
        C = C * (torch.exp(dtA)-1.) / A
        K = 2 * torch.einsum('hn, hnl -> hl', C, torch.exp(K)).real

        # End of S4D Kernel
        k = K # (H L)

        # Convolution
        k_f = torch.fft.rfft(k, n=2*L) # (H L)
        u_f = torch.fft.rfft(u, n=2*L) # (B H L)
        y = torch.fft.irfft(u_f*k_f, n=2*L)[..., :L] # (B H L)

        # Compute D term in state space equation - essentially a skip connection
        y = y + u * self.D.unsqueeze(-1)

        y = self.dropout(self.activation(y))
        y = self.output_linear(y)
        if not self.transposed: y = y.transpose(-1, -2)
        return y, None # Return a dummy state to satisfy this repo's interface, but this can be modified

    def register(self, name, tensor, lr=None):
        """Register a tensor with a configurable learning rate and 0 weight decay"""

        if lr == 0.0:
            self.register_buffer(name, tensor)
        else:
            self.register_parameter(name, nn.Parameter(tensor))

            optim = {"weight_decay": 0.0}
            if lr is not None: optim["lr"] = lr
            setattr(getattr(self, name), "_optim", optim)


class DropoutNd(nn.Module):
    def __init__(self, p: float = 0.5, tie=True, transposed=True):
        """
        tie: tie dropout mask across sequence lengths (Dropout1d/2d/3d)
        """
        super().__init__()
        if p < 0 or p >= 1:
            raise ValueError("dropout probability has to be in [0, 1), " "but got {}".format(p))
        self.p = p
        self.tie = tie
        self.transposed = transposed
        self.binomial = torch.distributions.binomial.Binomial(probs=1-self.p)

    def forward(self, X):
        """X: (batch, dim, lengths...)."""
        if self.training:
            if not self.transposed: X = rearrange(X, 'b ... d -> b d ...')
            mask_shape = X.shape[:2] + (1,)*(X.ndim-2) if self.tie else X.shape
            mask = torch.rand(*mask_shape, device=X.device) < 1.-self.p
            X = X * mask * (1.0/(1-self.p))
            if not self.transposed: X = rearrange(X, 'b d ... -> b ... d')
            return X
        return X
