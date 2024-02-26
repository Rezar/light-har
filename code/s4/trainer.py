import torch
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.metrics import accuracy_score


# Validate the model given the dataloader and return loss and accuracy
def validate(model, dataloader, device):
    model.eval()
    criterion = torch.nn.CrossEntropyLoss()
    running_loss = 0.0
    true_labels = []
    predicted_labels = []

    model.to(device)
    with torch.no_grad():
        for X_batch, y_batch in dataloader:
            inputs, labels = X_batch.to(device), y_batch.to(device)
            output = model(inputs)
            loss = criterion(output, labels)
            running_loss += loss.item()

            _, predicted = torch.max(output.data, 1)
            true_labels.extend(labels.cpu().numpy())
            predicted_labels.extend(predicted.cpu().numpy())

    avg_loss = running_loss / len(dataloader)
    accuracy = accuracy_score(true_labels, predicted_labels) * 100

    return avg_loss, accuracy

# Plot training history and save figures
def plot_or_save_metrics(num_epochs, train_losses, val_losses, val_accuracies, save_path=None, show_plot=True):
    epochs = range(1, num_epochs + 1)
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5))

    ax1.plot(epochs, train_losses, label='Training Loss', marker='o', color='blue')
    ax1.plot(epochs, val_losses, label='Validation Loss', marker='o', color='red')
    ax1.set_title('Training and Validation Losses')
    ax1.set_xlabel('Epochs')
    ax1.set_ylabel('Loss')
    ax1.legend()
    ax1.grid(True)

    ax2.plot(epochs, val_accuracies, label='Validation Accuracy', marker='o', color='green')
    ax2.set_title('Validation Accuracy')
    ax2.set_xlabel('Epochs')
    ax2.set_ylabel('Accuracy')
    ax2.legend()
    ax2.grid(True)

    fig.tight_layout()

    if save_path:
        fig.savefig(save_path+".png")

    if show_plot:
        plt.show()
    else:
        plt.close(fig)


def train(model, train_loader, test_loader, save_path=None, num_epochs=1, device='cuda', verbose=1):
    # Define the optimizer and loss function
    optimizer = torch.optim.Adam(model.parameters())
    loss_fn = torch.nn.CrossEntropyLoss()

    best_val_accuracy = 0.0 
    best_model_state = None

    train_losses = []
    val_losses = []
    val_accuracies = []

    model.to(device)
    for epoch in range(num_epochs):
        model.train()
        running_loss = 0.0

        # Training
        for X_batch, y_batch in train_loader:
            inputs, labels = X_batch.to(device), y_batch.to(device)
            optimizer.zero_grad()
            output = model(inputs)
            loss = loss_fn(output, labels)
            loss.backward()
            optimizer.step()
            running_loss += loss.item()
        avg_loss = running_loss / len(train_loader)
        train_losses.append(avg_loss)

        # Validating
        val_loss, val_acc = validate(model, test_loader, device)
        val_accuracies.append(val_acc)
        val_losses.append(val_loss)

        # Save the best model state
        if val_acc > best_val_accuracy:
            best_val_accuracy = val_acc
            best_model_state = model.state_dict()

        if verbose>0:
            print(f"Epoch [{epoch+1}/{num_epochs}], Train Loss: {avg_loss:.4f}, Val Accuracy: {val_acc:.2f}%")

    if verbose>0:
        print('Finished training')

    if val_acc < best_val_accuracy:
        model.load_state_dict(best_model_state)

        if verbose>0:
            print('Best model state restored')

    # Save the best model
    if save_path:
        torch.save(model.state_dict(), save_path+".pt")
        if verbose>0:
            print(f'Best model saved at {save_path}.pt')

    # Save the training history
    history_df = pd.DataFrame({
        'epoch': range(1, num_epochs + 1),
        'train_loss': train_losses,
        'val_loss': val_losses,
        'val_accuracy': val_accuracies
    })

    if save_path:
        history_df.to_csv(save_path+".csv", index=False)
        if verbose>0:
            print(f'Training history saved at {save_path}.csv')
    return train_losses, val_losses, val_accuracies

def load_and_plot_history(load_path):
    # Load the DataFrame from the CSV file
    history_df = pd.read_csv(load_path)

    # Extract training history
    epochs = history_df['epoch'].tolist()
    train_losses = history_df['train_loss'].tolist()
    val_losses = history_df['val_loss'].tolist()
    val_accuracies = history_df['val_accuracy'].tolist()

    # Plot the history
    plot_or_save_metrics(len(epochs), train_losses, val_losses, val_accuracies, save_path=None)