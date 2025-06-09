#!/bin/bash
# filepath: setup-jenkins-k8s.sh

# Đảm bảo script được chạy với quyền sudo
if [ "$(id -u)" -ne 0 ]; then
   echo "Script này cần được chạy với quyền sudo" 
   exit 1
fi

echo "Cấu hình quyền truy cập Kubernetes cho Jenkins..."

# Tạo thư mục .kube và .minikube cho user jenkins
mkdir -p /var/lib/jenkins/.kube
mkdir -p /var/lib/jenkins/.minikube

# Sao chép cấu hình
cp -f /home/fat/.kube/config /var/lib/jenkins/.kube/
cp -rf /home/fat/.minikube/* /var/lib/jenkins/.minikube/

# Thiết lập quyền
chown -R jenkins:jenkins /var/lib/jenkins/.kube
chown -R jenkins:jenkins /var/lib/jenkins/.minikube
chmod -R 755 /var/lib/jenkins/.kube
chmod -R 755 /var/lib/jenkins/.minikube

# Đảm bảo các file chứng chỉ có quyền đọc
find /var/lib/jenkins/.minikube -name "*.crt" -exec chmod 644 {} \;
find /var/lib/jenkins/.minikube -name "*.key" -exec chmod 644 {} \;

# Cập nhật file cấu hình để sử dụng đường dẫn mới
sed -i "s|/home/fat/.minikube|/var/lib/jenkins/.minikube|g" /var/lib/jenkins/.kube/config

echo "Kiểm tra cấu hình kubectl cho user jenkins..."
sudo -u jenkins kubectl config view

echo "Cấu hình hoàn tất."