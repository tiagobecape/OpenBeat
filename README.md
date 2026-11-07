# OpenBeat

Aplicação gratuita de reprodução de músicas offline e online para Android.

O protótipo v0.1 permite importar ficheiros de áudio para a biblioteca da sessão,
pesquisar pelo nome do ficheiro, reproduzir a demonstração online da MDN e usar
os controlos de pausa e posição.

## Compilar o APK no GitHub

1. Abre **Actions** e seleciona **Compilar OpenBeat APK**. O workflow corre
   automaticamente quando os ficheiros são publicados na branch `main`.
   Para repetir, seleciona **Run workflow** e escolhe `main`.
2. Abre a execução concluída. Em **Artifacts**, descarrega **OpenBeat-v0.1-APK**.
3. Extrai o ZIP e abre `OpenBeat-v0.1-debug.apk` no Android. Se o Android
   pedir autorização para instalar a partir da aplicação que abriu o ficheiro,
   concede-a para concluir a instalação.

O GitHub Actions usa Flutter 3.35.7, Java 17 e o SDK Android do runner.
O workflow gera o projeto Android numa pasta temporária, copia o código do
OpenBeat, ativa o acesso à internet, analisa o código e compila um APK de
depuração para testes. A instalação local do Android Studio é dispensável.

Para testar, importa um MP3 local e experimenta a pesquisa, a pausa e a barra
de posição. Com internet, toca na faixa de demonstração. A biblioteca é
recriada ao reiniciar a aplicação.
