#### Basic Commands

List Files and Directories:
```
# List all files in current directory
ls

# List with details (permissions, size, date, etc.)
ls -l

# List hidden files as well
ls -la
```

Change the current directory:
```
# Go to a directory
cd /home/username/Documents

# Go up one level
cd ..

# Go to home directory
cd ~
```

Create a new directory:
```
# Create a single directory
mkdir my_folder

# Create nested directories
mkdir -p parent_folder/child_folder
```

Create new file:
```
# Create an empty file
touch myfile.txt

# Create multiple files at once
touch file1.txt file2.txt
```

Copy Files or Directories:
```
# Copy a file
cp file1.txt copy_of_file1.txt

# Copy a directory recursively
cp -r my_folder backup_folder
```

Move or Rename Files or Directories:
```
# Rename a file
mv oldname.txt newname.txt

# Move a file to another folder
mv file.txt /home/username/Documents/

# Move and rename at the same time
mv file.txt /home/username/Documents/newfile.txt
```

Remove Files or Directories:
```
# Remove a file
rm file.txt

# Remove multiple files
rm file1.txt file2.txt

# Remove a directory and its contents
rm -r my_folder

# Remove without asking for confirmation
rm -rf my_folder
```

Print the Current Working Directory:
```
pwd
```

#### Tools

Nano
```
# Create or edit a file
nano myfile.txt
```

| Shortcut | Action                             |
| -------- | ---------------------------------- |
| `CTRL+O` | Save file (“Write Out”)            |
| `CTRL+X` | Exit Nano                          |
| `CTRL+G` | Help menu                          |
| `CTRL+K` | Cut the current line               |
| `CTRL+U` | Paste (after cut)                  |
| `CTRL+W` | Search in the file                 |
| `CTRL+C` | Show cursor position (line/column) |
Cat
View:
```
cat notes.txt

cat file1.txt file2.txt
```

Create:
```
cat > notes.txt
```

Append to an exiting file(Add Newline):
```
cat >> existing.txt
```

Number the lines in Output:
```
cat -n files.txt
```

#### File System Hierarchy Example
```
# Go to essential user binaries
cd /bin
ls

# View bootloader files
cd /boot
ls

# List device files
ls /dev

# View system configuration
cd /etc
ls

# Go to your home directory
cd /home/username

# View libraries
ls /lib

# Check removable media mount point
ls /media

# Go to temporary files folder
cd /tmp

# Explore process information
cd /proc
ls
```

#### File Permissions
Check File permissions:
```
ls -l
```

Change File Permissions:
```
# Add execute permission for owner
chmod u+x script.sh

# Remove write permission for others
chmod o-w file.txt

# Give read, write, execute to everyone
chmod 777 file.txt
```

Change Ownership:
```
# Change file owner
sudo chown newuser file.txt

# Change group owner
sudo chown :newgroup file.txt

# Change both owner and group
sudo chown newuser:newgroup file.txt
```

File Permission Using Numeric Mode
u - user
g - group
o - others

r = 4
w = 2
x = 1

#### User and Group Management
```
#List of all groups
cat /etc/group

#Personal groups
cut -d: -f1 /etc/group

# Create a group
sudo groupadd demo_group

# Create a user in that group
sudo useradd -m -g demo_group demo_user

# Set password
echo "demo_user:password123" | sudo chpasswd

# Add to sudo group
sudo usermod -aG sudo demo_user

# Remove user
sudo deluser demo_user

# Remove group
sudo delgroup demo_group
```

Access Control List
- provides an additional, more flexible permission mechanism for file system. 

Commands:
- To add permission for user
```
setfacl -m u:user:rwx /path/to/file
```

- To add permissions for a group
```
setfacl -m g:group:rw /pat/to/file
```

- To allow all files or directories to inherit ACL entries from the directory it is within
```
setfacl -dm "entry" /path/to/dir
```

- To remove a specific entry
```
setfacl -x u:user /path/to/file (for specific user)
```

- To remove all entries
```
setfacl -b path/to/file (for all users)
```

#### Process Management
```
# List processes
ps aux | head -n 5

# Interactive process viewer
top  # press 'q' to quit
```

#### Service Management
```
# List running services
systemctl list-units --type=service --state=running | head -n 5

# Start/stop/restart a service
sudo systemctl start <service>
sudo systemctl stop <service>
sudo systemctl restart <service>
```

#### Package Management
```
# Debian/Ubuntu
sudo apt update
sudo apt install <package>

# RHEL/CentOS
sudo yum install <package>

# Fedora
sudo dnf install <package>
```

#### Files System Structure and its Description
- **/boot** - contains file that is used by the boot loader
- **/root** - root user home directory. It is not same as /
- **/dev** - system devices
- **/etc** - configuration files
- **/bin** -> **/usr/bin** - everyday user commands
- **/sbin** -> **/usr/sbin** - system/filesystem commands
- **/opt** - optional add-on applications (Not part of OS apps)
- **/proc** - running processes (only exist in memory)
- **/lib** -> **usr/lib** - C programming library files needed by commands and apps
```
strace -e open pwd
```
- **/tmp** - directory for temporary files
- **/home** - directory for user
- **/var** - system logs
- **/run** - system daemons that start very early to store temporary runtime files like PID files
- **/mnt** - to mount external filesystems
- **/media** - for cdrom mounts.

#### Linux File Types

| File Symbol | Meaning                     |
| ----------- | --------------------------- |
| -           | Regular file                |
| d           | Directory                   |
| l           | link                        |
| c           | Special file or device file |
| s           | socket                      |
| p           | named pipe                  |
| b           | Block device                |
