# Skill: WhiskeySockets Baileys — WhatsApp Web API
# Natural Tecnologia — nt-usina
# Arquivo: .claude/skills/stack-baileys.md
#
# USO: Injetar no Coding Agent para projetos com integração WhatsApp via Baileys.
# Biblioteca: @whiskeysockets/baileys (Node.js)

---

## Instalação e dependências

```json
{
  "dependencies": {
    "@whiskeysockets/baileys": "^6.7.0",
    "pino": "^9.0.0",
    "qrcode-terminal": "^0.12.0",
    "@hapi/boom": "^10.0.1"
  }
}
```

---

## Conexão e autenticação

```javascript
import makeWASocket, {
    DisconnectReason,
    useMultiFileAuthState,
    fetchLatestBaileysVersion,
    makeInMemoryStore,
} from '@whiskeysockets/baileys'
import pino from 'pino'
import { Boom } from '@hapi/boom'

const logger = pino({ level: 'silent' })  // 'debug' em dev, 'silent' em prod

async function conectar() {
    // Auth persistente em disco — essencial para evitar novo QR a cada reinício
    const { state, saveCreds } = await useMultiFileAuthState('auth_info')
    const { version } = await fetchLatestBaileysVersion()

    const sock = makeWASocket({
        version,
        auth: state,
        logger,
        printQRInTerminal: true,         // QR no terminal para primeiro login
        generateHighQualityLinkPreview: true,
    })

    // Persistir credenciais a cada atualização
    sock.ev.on('creds.update', saveCreds)

    // Gerenciar reconexão
    sock.ev.on('connection.update', ({ connection, lastDisconnect, qr }) => {
        if (connection === 'close') {
            const deveReconectar = (lastDisconnect?.error as Boom)?.output?.statusCode
                !== DisconnectReason.loggedOut
            if (deveReconectar) conectar()
        }
    })

    return sock
}
```

---

## Envio de mensagens

```javascript
// Texto simples
await sock.sendMessage(jid, { text: 'Olá! Como posso ajudar?' })

// Texto com formatação WhatsApp
await sock.sendMessage(jid, {
    text: '*Negrito* _itálico_ ~tachado~ ```código```'
})

// Imagem
await sock.sendMessage(jid, {
    image: fs.readFileSync('imagem.jpg'),
    caption: 'Legenda da imagem',
})

// Imagem via URL
await sock.sendMessage(jid, {
    image: { url: 'https://exemplo.com/imagem.jpg' },
    caption: 'Legenda',
})

// Documento/arquivo
await sock.sendMessage(jid, {
    document: fs.readFileSync('relatorio.pdf'),
    mimetype: 'application/pdf',
    fileName: 'relatorio.pdf',
})

// Áudio
await sock.sendMessage(jid, {
    audio: fs.readFileSync('audio.mp3'),
    mimetype: 'audio/mpeg',
    ptt: true,  // true = mensagem de voz, false = arquivo de áudio
})

// Responder mensagem específica
await sock.sendMessage(jid, {
    text: 'Resposta aqui',
}, { quoted: mensagemOriginal })

// Botões (limitado pelo WhatsApp — verificar disponibilidade)
await sock.sendMessage(jid, {
    text: 'Escolha uma opção:',
    buttons: [
        { buttonId: 'opt1', buttonText: { displayText: 'Opção 1' }, type: 1 },
        { buttonId: 'opt2', buttonText: { displayText: 'Opção 2' }, type: 1 },
    ],
    headerType: 1,
})
```

---

## Formato de JID (identificador)

```javascript
// Contato individual
const jid = '5571999887766@s.whatsapp.net'  // DDI + DDD + número

// Grupo
const jidGrupo = '120363xxxxxxxxxx@g.us'

// Construir JID a partir de número
function numeroParaJid(numero) {
    // Remover caracteres não numéricos
    const limpo = numero.replace(/\D/g, '')
    return `${limpo}@s.whatsapp.net`
}

// Verificar se número existe no WhatsApp
const [resultado] = await sock.onWhatsApp('+5571999887766')
if (resultado?.exists) {
    const jid = resultado.jid
}
```

---

## Recebimento e processamento de mensagens

```javascript
sock.ev.on('messages.upsert', async ({ messages, type }) => {
    if (type !== 'notify') return  // ignorar mensagens históricas

    for (const msg of messages) {
        if (msg.key.fromMe) continue  // ignorar mensagens enviadas pelo bot

        const jid     = msg.key.remoteJid
        const isGrupo = jid?.endsWith('@g.us')
        const texto   = extrairTexto(msg)

        if (!texto) continue

        await processarMensagem({ sock, msg, jid, texto, isGrupo })
    }
})

// Extrair texto de diferentes tipos de mensagem
function extrairTexto(msg) {
    return msg.message?.conversation
        || msg.message?.extendedTextMessage?.text
        || msg.message?.imageMessage?.caption
        || msg.message?.videoMessage?.caption
        || ''
}

// Extrair número do remetente
function extrairNumero(jid) {
    return jid.replace('@s.whatsapp.net', '').replace('@g.us', '')
}
```

---

## Padrões de arquitetura para bots

### Estrutura recomendada

```
src/
├── bot/
│   ├── conexao.js         # Gerencia conexão Baileys e reconexão
│   ├── handlers/
│   │   ├── mensagem.js    # Handler principal de mensagens recebidas
│   │   ├── comandos.js    # Roteamento de comandos (/start, /ajuda, etc.)
│   │   └── midias.js      # Handler para imagens, áudios, documentos
│   └── middlewares/
│       ├── rateLimit.js   # Limitar mensagens por número
│       └── blocklist.js   # Números bloqueados
├── services/              # Lógica de negócio
├── repositories/          # Persistência (sessões, histórico)
└── auth_info/             # Credenciais Baileys (ignorar no .gitignore)
```

### Gerenciamento de sessão de conversa

```javascript
// Manter estado da conversa por número
const sessoes = new Map()

function obterSessao(jid) {
    if (!sessoes.has(jid)) {
        sessoes.set(jid, { etapa: 'inicio', dados: {}, ultimaAtividade: Date.now() })
    }
    return sessoes.get(jid)
}

// Limpar sessões inativas (ex: após 30 min)
setInterval(() => {
    const agora = Date.now()
    for (const [jid, sessao] of sessoes) {
        if (agora - sessao.ultimaAtividade > 30 * 60 * 1000) {
            sessoes.delete(jid)
        }
    }
}, 5 * 60 * 1000)
```

---

## Boas práticas e limitações

```
✓ Sempre usar useMultiFileAuthState para persistir sessão em disco
✓ Implementar reconexão automática com verificação de loggedOut
✓ Rate limiting: evitar envio massivo em curto período (risco de ban)
✓ Respeitar horários — evitar mensagens fora do horário comercial
✓ Tratar erros de envio (número inexistente, bloqueado, etc.)
✓ Log de todas as mensagens para auditoria

✗ Nunca enviar spam ou mensagens não solicitadas
✗ Nunca armazenar credenciais auth_info no repositório Git
✗ Nunca usar para fins que violem os Termos de Uso do WhatsApp
✗ Limitar envio simultâneo — máximo 5-10 mensagens por segundo
```

### .gitignore — adicionar obrigatoriamente

```
auth_info/
*.session
```

---

## Armadilhas comuns

```
✗ Não persistir credenciais → novo QR a cada reinício
✗ Não tratar reconexão     → bot para de funcionar após queda
✗ Usar jid sem @s.whatsapp.net → mensagem não entregue
✗ Ignorar type !== 'notify' → processar mensagens históricas duplicadas
✗ Não verificar msg.key.fromMe → loop de auto-resposta
✗ Envio síncrono em massa  → bloqueio por rate limiting do WhatsApp
```
