def addiere(a, b):
    return a + b

def test_addiere_korrekt():
    assert addiere(2, 3) == 5

def test_addiere_fehler():
    assert addiere(10, 10) == 20
