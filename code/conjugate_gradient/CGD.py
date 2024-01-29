import torch
import copy

class ConjugateGradientDescent(torch.optim.Optimizer):
    def __init__(self, model, loss_fn, X, y):
        self.model = model
        self.params = list(model.parameters())
        self.loss_fn = loss_fn
        self.X = X
        self.y = y
        self.prev_gradient = None

    def step(self):
        if self.prev_gradient is None:
            direction = [-param.grad for param in self.params]
        else:
            direction = self._compute_conjugate_direction()

        step_size = self._line_search(direction)
        print(f"Step size: {step_size:.8f}")

        for i, param in enumerate(self.params):
            param.data += step_size * direction[i]

        self.prev_gradient = [-d for d in direction]

    def zero_grad(self):
        for param in self.params:
            if param.grad is not None:
                param.grad.data.zero_()

    def _compute_conjugate_direction(self):
        conjugate_directions = [torch.zeros_like(param) for param in self.params]

        for i, param in enumerate(self.params):
            current_grads = param.grad

            # Beta calculation based on Polak-Ribiere equation
            beta_numerator = torch.dot(current_grads.flatten(), (current_grads - self.prev_gradient[i]).flatten())
            beta_denominator = torch.dot(self.prev_gradient[i].flatten(), self.prev_gradient[i].flatten())
            beta = beta_numerator / beta_denominator

            conjugate_directions[i] = -current_grads - beta * self.prev_gradient[i]

        return conjugate_directions

    # A back-tracking line search
    def _line_search(self, search_direction, max_iter = 100, alpha = 0.3, beta = 0.8, min_step = 1e-8):
        step_size = 1.0
        grads = [param.grad for param in self.params]

        flat_grad = torch.cat([g.flatten() for g in grads])
        flat_p = torch.cat([p.flatten() for p in search_direction])

        for _ in range(max_iter):
            trial_model = copy.deepcopy(self.model)

            with torch.no_grad():
                for param, direction in zip(trial_model.parameters(), search_direction):
                    param += step_size * direction

            trial_pred = trial_model.forward(self.X)
            trial_loss = self.loss_fn(trial_pred, self.y)

            # Check the Armijo condition
            if trial_loss <= self.loss_fn(self.model(self.X), self.y) + alpha * step_size * torch.dot(flat_grad, flat_p):
                break

            step_size *= beta

            if step_size < min_step:
                break

        return step_size