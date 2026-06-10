import os
from dotenv import load_dotenv

load_dotenv()

print("Die geladene Stage ist:", os.getenv("STAGE"))
print("Der Secret Key ist:", os.getenv("SECRET_KEY"))
