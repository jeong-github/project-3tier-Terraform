#!/bin/bash
sudo -i
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd
echo 'qwe123' | passwd --stdin root
cd /var/www/html

cat > /var/www/html/index.php <<EOF
<?php
\$servername = "${end_point_name}";
\$username = "${user_name}";
\$password = "${user_password}";


\$conn = new mysqli(\$servername, \$username, \$password);


if (\$conn->connect_error) {
  die("Connection failed: " . \$conn->connect_error);
}
echo "Connected successfully";
?>
EOF
systemctl restart httpd


