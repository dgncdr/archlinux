# How to Use arch-clean-install.sh

You’ll need two USB drives:
    USB #1 – Arch Linux Installer
        Flash the official Arch ISO using Rufus or your tool of choice.
        This is your bootable installer.
    USB #2 – The Install Script
        Format this drive as exFAT (so Linux can read it without extra packages).
        Copy the install script to the root of this drive.

If You’re Using Windows to Create the Script:

If you’re editing the script on Windows, make sure:
    Encoding is set to UTF-8
    Line endings are set to UNIX (LF), not Windows (CRLF)

You can use Notepad++ to check this:
    Click on Encoding → Convert to UTF-8 (without BOM)
    Then Edit → EOL Conversion → UNIX (LF)
    
Then follow the steps below
1. Identify the USB with the script

   lsblk
   
   Look for the one that's NOT your bootable installer (e.g. /dev/sdX1)

3. Create a temp folder to mount it

   mkdir /mediatemp

6. Mount the USB
  
   mount /dev/sdX1 /mediatemp

5. Make the script executable
  
   chmod +x /mediatemp/your-script-name.sh

8. Run the script
  
    /mediatemp/your-script-name.sh
