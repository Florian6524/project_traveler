import qrcode

codes = [
    "museum_001",
    "park_001",
    "cafe_001",
    "test_Florian",
    "test_voicea",
    "robo"
]

for code in codes:
    img = qrcode.make(code)

    img.save(f"{code}.png")

print("QR codes generated!")