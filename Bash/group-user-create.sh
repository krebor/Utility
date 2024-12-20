#!/bin/bash

#Create group with unique name
echo "Enter group name:"

read GROUPNAME

while grep -i "$GROUPNAME" /etc/group > /dev/null
do
	echo "Group name already taken. Please choose another."
	read GROUPNAME
done

groupadd "$GROUPNAME"

#Create user with unique name, belonging to the created group and set password
echo "Enter user name:"

read USERNAME

while grep -i "$USERNAME" /etc/passwd > /dev/null
do
	echo "Username already taken. Please choose another."
	read USERNAME
done

useradd -g "$GROUPNAME" -s /bin/bash "$USERNAME"

echo "Set user password: "

passwd "$USERNAME"

#Create directory at / with chosen username and set user/group ownership with sticky bit

mkdir /"$USERNAME"
chown "$USERNAME":"$GROUPNAME" /"$USERNAME"
chmod 1770 /"$USERNAME"