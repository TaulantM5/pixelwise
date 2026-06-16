def addiere(a, b):
    return a + b

def test_addiere_korrekt():
    assert addiere(2, 3) == 5

def test_addiere_fehler():
    assert addiere(10, 10) == 20


def test_absichtlicher_fehler():
    assert addiere(2, 2) == 4
