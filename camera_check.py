import cv2

def check_cameras(limit=5):
    available_cams = []
    for i in range(limit):
        cap = cv2.VideoCapture(i)
        if cap.isOpened():
            print(f"Camera found: Index {i}")
            available_cams.append(i)
            cap.release()
        else:
            print(f"No camera at: Index {i}")
    return available_cams

check_cameras()
