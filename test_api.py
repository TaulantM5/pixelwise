import requests
from sklearn.datasets import fetch_openml

print("Lade MNIST-Testbild für die API... (einen Moment)")
X, y = fetch_openml("mnist_784", version=1, return_X_y=True, as_frame=False)

# Erstes Bild extrahieren und als Liste von Listen (28x28) formatieren
sample = X[0].reshape(28, 28).tolist()

# Daten an den neuen /predict Endpunkt senden
url = "http://127.0.0.1:8000/predict"
response = requests.post(url, json={"image": sample})

print("\n--- API ANTWORT ---")
print(f"Status Code: {response.status_code}")
print(f"Antwort vom Server: {response.json()}")
print(f"Tatsächliche Ziffer: {y[0]}")
