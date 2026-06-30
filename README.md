Usage:
  bash dns.sh domain.com

Or make it executable:
  chmod +x dns.sh
  ./dns.sh domain.com

Optional alias:
  alias dns='bash /path/to/dns.sh'

  Make the alias permanent:

Bash:
  echo "alias dns='bash /path/to/dns.sh'" >> ~/.bashrc
  source ~/.bashrc

Zsh:
  echo "alias dns='bash /path/to/dns.sh'" >> ~/.zshrc
  source ~/.zshrc
