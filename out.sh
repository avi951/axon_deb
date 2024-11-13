#!/bin/bash

sudo systemctl disable test-axon.service
sudo systemctl stop test-axon.service
sudo systemctl daemon-reload
sudo rm -rf /test
sudo rm -rf /etc/systemd/system/test-axon.service
sudo rm -rf /usr/local/bin/auto-test.sh
sudo rm -rf /opt/test_axon.txt
sudo rm -rf /home/vicharak/recorded_output.wav
sudo rm -rf /home/vicharak/rtc_time.txt
sudo reboot
