#!/bin/env bash

sudo cp -v test-axon.service /etc/systemd/system
sudo cp -v auto-test.sh /usr/local/bin
sudo mkdir /test
sudo cp -v axon-test.sh /test
sudo cp -v Jai\ Ho.mp3  /test
sudo cp -v camera_csi_11.py /test
sudo cp -v camera_csi_31.py /test
sudo cp -v camera_dphy_22.py /test
sudo cp -v read_gpio.sh /test
sudo cp -v write_gpio.sh /test
sudo cp -v v4l2grab /test
sudo cp -v axon-overlays_1.0.0_arm64.deb /test
sudo cp -v rtc_time.txt /test
sudo cp -v gpio_check.py /test
sudo cp -v results.log /test
echo "Trying to on test-service"
sudo systemctl daemon-reload
sudo systemctl enable test-axon.service
sudo systemctl status test-axon.service
sleep 1
sudo poweroff
