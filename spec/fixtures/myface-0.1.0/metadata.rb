name             "myface"
maintainer       "Jamie Winsor"
maintainer_email "reset@riotgames.com"
license          "Apache 2.0"
description      "Installs/Configures myface"
long_description "Installs/Configures myface"
version          "0.1.0"

%w{ centos }.each do |os|
  supports os
end

depends "nginx", "~> 1.0.0"
depends "artifact", "~> 0.11.5"
