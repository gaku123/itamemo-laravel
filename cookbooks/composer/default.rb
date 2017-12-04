execute "setup composer" do
  user "root"
  command "php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\" && php composer-setup.php --install-dir=/usr/local/bin --filename=composer"
  not_if "/usr/local/bin/composer -V"
end
