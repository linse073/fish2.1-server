scp -i ./id_rsa.by ../fish/lib/* ubuntu@146.56.234.157:~/fish01/fish-server/fish/lib/
scp -i ./id_rsa.by ../fish/data/*.lua ubuntu@146.56.234.157:~/fish01/fish-server/fish/data
scp -i ./id_rsa.by ../fish/service/* ubuntu@146.56.234.157:~/fish01/fish-server/fish/service
ssh -i ./id_rsa.by ubuntu@146.56.234.157 "~/server_shell_01/restart.sh"