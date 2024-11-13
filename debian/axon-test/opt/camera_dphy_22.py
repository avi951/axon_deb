#!/usr/bin/python3
import cv2
import os

cap = cv2.VideoCapture(22)
count = 0

while True:
    ret, frame = cap.read()
    cv2.imshow('frame', frame)
    count+=1
#    print(count)
    if count == 15:
        cv2.imwrite('/home/vicharak/test_dphy.png',frame)
        print("Image captured")
        break
        cv2.imshow('captured frame', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
# After the loop release the cap object
cap.release()
# Destroy all the windows
cv2.destroyAllWindows()
os.remove("/home/vicharak/test_dphy.png")
