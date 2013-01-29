name             "motherbrain"
maintainer       "Jamie Winsor"
maintainer_email "jamie@vialstudios.com"
license          "Apache 2.0"
description      "Installs/Configures motherbrain"
long_description "Installs/Configures motherbrain"
version          "0.1.0"

%w{ centos }.each do |os|
  supports os
end

depends "nginx", "~> 1.0.0"
depends "artifact", "~> 0.11.5"
