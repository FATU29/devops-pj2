#!/bin/bash
# filepath: /home/fat/code/devops/spring-petclinic-microservices/scripts/create-mvnw.sh

echo "=== Tạo Maven Wrapper cho tất cả service ==="
echo

# Di chuyển đến thư mục gốc của dự án
cd /home/fat/code/devops/spring-petclinic-microservices

# Kiểm tra và tạo Maven Wrapper cho tất cả service
for service in spring-petclinic-*; do
  if [ -d "$service" ]; then
    echo "📂 Xử lý $service..."
    
    cd "$service"
    
    # Tạo Maven Wrapper nếu chưa có
    if [ ! -f "mvnw" ] || [ ! -d ".mvn" ]; then
      echo "  🔧 Đang tạo Maven Wrapper..."
      mvn -N wrapper:wrapper
      echo "  ✅ Đã tạo Maven Wrapper"
    else
      echo "  ℹ️ Maven Wrapper đã tồn tại"
    fi
    
    # Đảm bảo quyền thực thi
    if [ -f "mvnw" ] && [ ! -x "mvnw" ]; then
      echo "  🔧 Đang cấp quyền thực thi cho mvnw..."
      chmod +x mvnw
      echo "  ✅ Đã cấp quyền thực thi"
    fi
    
    cd ..
    echo
  fi
done

echo "=== Hoàn tất tạo Maven Wrapper ==="