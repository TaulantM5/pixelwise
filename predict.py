import numpy as np
from sklearn.datasets import fetch_openml
from app.classifier import classify

print("Lade MNIST-Testdaten... (kann kurz dauern)")
X, y = fetch_openml("mnist_784", version=1, return_X_y=True, as_frame=False)

# Wir nehmen wieder das erste Bild als Test
sample = X[0].reshape(28, 28).astype("uint8")
true_label = y[0]

# Jetzt jagen wir es durch unser neues Modul!
result = classify(sample)

print("\n--- TEST ERGEBNIS ---")
print(f"Vorhergesagte Ziffer: {result['prediction']}")
print(f"Sicherheit (Confidence): {result['confidence']:.2f}")
print(f"Tatsächliche Ziffer: {true_label}")
print("----------------------")
