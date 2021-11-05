scp -i ./id_rsa.by ../fish/lib/* ubuntu@146.56.234.157:~/fish02/fish2-server/fish/lib/
scp -i ./id_rsa.by ../fish/data/*.lua ubuntu@146.56.234.157:~/fish02/fish2-server/fish/data
scp -i ./id_rsa.by ../fish/service/* ubuntu@146.56.234.157:~/fish02/fish2-server/fish/service
ssh -i ./id_rsa.by ubuntu@146.56.234.157 "~/server_shell_02/restart.sh"