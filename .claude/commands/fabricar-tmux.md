# /fabricar-tmux

Abre o ambiente de trabalho da Natural Tecnologia no Windows Terminal com 4 painéis.

## O que este comando faz

Executa `scripts\Start-Usina.ps1`, que abre uma nova janela do Windows Terminal
com 4 painéis configurados para monitoramento do pipeline nt-usina em tempo real.

## Pré-requisitos

- Windows Terminal instalado
  ```powershell
  winget install Microsoft.WindowsTerminal
  ```
- PowerShell 5.1 ou superior (já incluso no Windows 10/11)
- Estar na raiz do projeto `nt-usina`

## Execução

```powershell
# A partir da raiz do projeto
.\scripts\Start-Usina.ps1

# Especificando log customizado
.\scripts\Start-Usina.ps1 -LogPath "caminho\para\app.log"
```

> Nota: se o PowerShell bloquear a execução por política de scripts, execute uma vez:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
> ```

## Layout dos painéis

| Painel | Conteúdo | Atualização |
|---|---|---|
| 1 — topo esquerda | Claude Code CLI (entrada de comandos) | Manual |
| 2 — topo direita | `backlog\indice.json` com status por cor | A cada 2s |
| 3 — baixo esquerda | `git log --oneline --graph` | A cada 5s |
| 4 — baixo direita | Log da aplicação em tempo real | Contínuo |

## Cores do Backlog Monitor (Painel 2)

| Cor | Status |
|---|---|
| Verde | `concluida` |
| Ciano | `em_desenvolvimento` |
| Amarelo | `em_testes` |
| Magenta | `em_recuperacao` |
| Vermelho | `bloqueada` |
| Cinza | `nao_iniciada` |

## Navegação no Windows Terminal

| Atalho | Ação |
|---|---|
| `Alt + Seta` | Mover entre painéis |
| `Alt + Shift + +` | Novo split vertical |
| `Alt + Shift + -` | Novo split horizontal |
| `Ctrl + Shift + W` | Fechar painel atual |
| `Ctrl + Shift + T` | Nova aba |
| Scroll do mouse | Rolar histórico do painel |
