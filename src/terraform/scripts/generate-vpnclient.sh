#! /bin/bash -e

ssh -i $SSH_KEY $OPENVPN_USER@$OPENVPN_SERVER "bash client-configs/make_config.sh $CLIENT_NAME"
sleep 5
sftp -i $SSH_KEY $OPENVPN_USER@$OPENVPN_SERVER:client-configs/files/$CLIENT_NAME.ovpn .