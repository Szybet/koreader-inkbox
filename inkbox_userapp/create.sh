#!/bin/bash -x

cd ../

rm -rf inkbox_userapp/koreader/app-bin/*

cp -r koreader inkbox_userapp/koreader/app-bin/

# Very important
rm -f inkbox_userapp/koreader.isa.dgst
rm -f inkbox_userapp/koreader.isa

mksquashfs inkbox_userapp/koreader/* inkbox_userapp/koreader.isa

# Yes, here are my private keys. Is providing this info a security threat? no.
openssl dgst -sha256 -sign /home/szybet/inkbox-keys/userapps.pem -out inkbox_userapp/koreader.isa.dgst inkbox_userapp/koreader.isa

# Create the zip
cd inkbox_userapp/
rm -rf koreader_inkbox.zip
mkdir -p tmp_koreader_dir/koreader/
cp app.json tmp_koreader_dir/koreader/
cp koreader.isa tmp_koreader_dir/koreader/
cp koreader.isa.dgst tmp_koreader_dir/koreader/
cd tmp_koreader_dir
zip -r koreader_inkbox.zip koreader/
mv koreader_inkbox.zip ../
cd ..
rm -rf tmp_koreader_dir

servername="root@10.42.0.28"
passwd="root"

sshpass -p $passwd ssh $servername "bash -c \"ifsctl mnt rootfs rw\""
# sshpass -p $passwd ssh $servername "bash -c \"rm -r /data/onboard/.apps/koreader\""
sshpass -p $passwd ssh $servername "bash -c \"mkdir /data/onboard/.apps/koreader\""
sshpass -p $passwd ssh $servername "bash -c \"rm  /data/onboard/.apps/koreader/koreader.isa\""
sshpass -p $passwd ssh $servername "bash -c \"rm  /data/onboard/.apps/koreader/koreader.isa.dgst\""
sshpass -p $passwd ssh $servername "bash -c \"rm  /data/onboard/.apps/koreader/app.json\""

cd ../
sshpass -p $passwd scp inkbox_userapp/app.json $servername:/data/onboard/.apps/koreader/
sshpass -p $passwd scp inkbox_userapp/koreader.isa.dgst $servername:/data/onboard/.apps/koreader/
sshpass -p $passwd scp inkbox_userapp/koreader.isa $servername:/data/onboard/.apps/koreader/

sshpass -p $passwd ssh $servername "bash -c \"touch /kobo/tmp/rescan_userapps\""

sshpass -p $passwd ssh $servername "bash -c \"sync\""

sshpass -p $passwd ssh $servername "bash -c \"killall -9 koreader-debug.sh\"" || EXIT_CODE=0
sshpass -p $passwd ssh $servername "bash -c \"killall -9 koreader.sh\"" || EXIT_CODE=0

sshpass -p $passwd ssh $servername "bash -c \"rc-service gui_apps restart\""
# sshpass -p $passwd ssh $servername "bash -c \"rc-service gui_apps restart\""

# To update main json
# sshpass -p $passwd ssh $servername "bash -c \"touch /kobo/tmp/rescan_userapps\"" # This gets deleted by service restart
#sshpass -p $passwd ssh $servername "bash -c \"killall inkbox-bin\""
#sleep 10
