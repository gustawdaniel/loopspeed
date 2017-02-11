Install gitlab runner locally

    curl -sSL https://get.docker.com/ | sh
    curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | sudo bash
    sudo apt-get install gitlab-ci-multi-runner

Install docker 

    curl -fsSL https://apt.dockerproject.org/gpg | sudo apt-key add -
    
<!--Docker for all users:-->    
    <!--sudo groupadd docker-->
    <!--sudo gpasswd -a ${USER} docker-->
    <!--sudo service docker restart-->

Test by docker

    sudo gitlab-runner exec docker test
    
    sudo apt-get install git
    git clone -depth=1 http://github.com/gustawdaniel/loopspeed && cd loopspeed
    bash install.sh
    
    