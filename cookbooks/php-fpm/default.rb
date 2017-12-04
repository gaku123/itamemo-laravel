package 'php71-fpm' do
  user 'root'
end

service 'php-fpm' do
  user 'root'
  action [:enable, :start]
end
