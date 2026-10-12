# Telão · iPad

App iOS do Telão, feito para o **iPad** (também roda no iPhone). Abre
`https://devlumo.com.br/telao/` em tela cheia num `WKWebView`, com o layout de app do site
(tela de toque até 1400px) e o que o navegador sozinho não faz:

- bloqueia as janelas de anúncio que os players abrem ao tocar no play;
- não deixa anúncio trocar a página principal (os players seguem livres nos iframes);
- vídeo em tela cheia, picture-in-picture, todas as orientações no iPad;
- som mesmo com o iPad no silencioso; puxar para atualizar; tela de "sem conexão".

## Gerar o .ipa

No Windows não dá para compilar iOS: o GitHub Actions compila num Mac
(`.github/workflows/ios.yml`) a cada push na `main`, ou em **Actions → iOS → Run workflow**.
O `Telao.ipa` sai **sem assinatura**, como artefato da execução.

```bash
gh run download --repo THTECH296/telao-ios --name Telao-ipa
```

## Instalar no iPad

Abra o **iloader** (ou Sideloadly), conecte o iPad, escolha o `Telao.ipa` e entre com o seu
ID Apple. Com ID Apple gratuito o app vale 7 dias e precisa ser reinstalado depois.

No primeiro uso: Ajustes → Geral → VPN e Gerenciamento de Dispositivos → confiar no seu ID Apple.
