execute "install laravel" do
  command "/usr/local/bin/composer global require 'laravel/installer'"
  not_if "laravel -V"
end
