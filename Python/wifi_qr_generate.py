import qrcode

# Wi-Fi details
ssid = "xxxxxx"
password = "xxxxxxx"
encryption = "WPA2"  # Options: WPA, WPA2, WEP, or leave empty for open networks

# Wi-Fi QR code format
wifi_data = f"WIFI:S:{ssid};T:{encryption};P:{password};;"

# Generate QR Code
qr = qrcode.QRCode(
    version=1,
    error_correction=qrcode.constants.ERROR_CORRECT_L,
    box_size=10,
    border=4,
)
qr.add_data(wifi_data)
qr.make(fit=True)

# Create and save the QR code image
img = qr.make_image(fill_color="black", back_color="white")
img.save("wifi_qrcode.png")