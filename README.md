# Diário de Viagem (tm_diario_viagem)

Trabalho de faculdade: app Flutter de diário/planejador de viagens, com foco em
demonstrar a comunicação com a internet (biblioteca **dio**, consumindo uma API
REST) e a persistência de dados em tempo real com o **Firebase Cloud
Firestore**.

## Objetivo do app

Cadastrar viagens (destino, datas, orçamento, anotações) e enriquecer cada uma
com dados buscados na internet: ao digitar o nome de uma cidade, o app busca a
localização real dela (país, latitude e longitude) numa API pública. O usuário
também registra manualmente suas compras de dólar para acompanhar se o
orçamento da viagem está sendo atingido.

## APIs consumidas

| API | Onde é usada | Por quê |
|---|---|---|
| [Open-Meteo Geocoding](https://open-meteo.com/en/docs/geocoding-api) | Tela de cadastro/edição de viagem, ao buscar uma cidade | Transforma o nome digitado pelo usuário em país, latitude e longitude reais, sem precisar de chave de API |

Toda chamada passa pelo `Dio` configurado em
[`lib/services/api_client.dart`](lib/services/api_client.dart), que tem um
`LogInterceptor` — por isso, rodando o app com `flutter run`, dá para ver no
console cada requisição e resposta HTTP em tempo real durante a apresentação.

> O controle de câmbio (compra de dólares) é **100% manual**: o próprio
> usuário digita a cotação que pagou em cada compra. Não há chamada
> automática de cotação, por escolha de projeto — o foco de API neste
> trabalho é a geocodificação.

## Como os dados do Firestore são usados em cada tela

Tudo fica na coleção `viagens`, mais uma subcoleção `compras` dentro de cada
viagem (`viagens/{id}/compras`) para as compras de dólar.

- **Lista de viagens** ([`lista_viagens_screen.dart`](lib/screens/lista_viagens_screen.dart)):
  o `ViagensBloc` ([`viagens_bloc.dart`](lib/blocs/viagens_bloc.dart)) assina a
  coleção `viagens` no `ViagemProvider` e emite um novo estado a cada
  atualização; a tela só consome esse estado com `BlocBuilder`, ordenada por
  data de ida. Cada card mostra a foto da viagem (ou um ícone, se não houver),
  destino, país, datas, orçamento e um selo de status calculado a partir das
  datas salvas ("Faltam X dias", "Em andamento" ou "Viagem realizada").
  Arrastar um card para a esquerda
  exclui a viagem (com confirmação).
- **Cadastro/edição** ([`form_viagem_screen.dart`](lib/screens/form_viagem_screen.dart)):
  escreve (cria ou atualiza) um documento na coleção `viagens`, incluindo os
  dados vindos da geocodificação (país, latitude, longitude) e a foto de
  capa escolhida pelo usuário.
- **Detalhe da viagem** ([`detalhe_viagem_screen.dart`](lib/screens/detalhe_viagem_screen.dart)):
  o `DetalheViagemBloc` ([`detalhe_viagem_bloc.dart`](lib/blocs/detalhe_viagem_bloc.dart))
  assina ao mesmo tempo o documento da viagem e a subcoleção de compras de
  dólar no `ViagemProvider`/`CompraDolarProvider`, combinando as duas streams
  num único estado; a tela consome esse estado com `BlocBuilder` e mostra
  todos os campos salvos: dados da viagem, um mapa-múndi com um pin na
  latitude/longitude salva, a lista de compras de dólar com um totalizador em
  reais, e as anotações do diário — editáveis direto nessa tela, sem precisar
  abrir o formulário completo.

Ou seja: nenhum campo salvo fica "esquecido" — todos aparecem em alguma tela.
Nenhuma tela fala diretamente com o Firestore: toda atualização em tempo real
passa pela camada Bloc (View → Bloc → Provider → Firestore).

## Assistente de viagem (Bloc)

Tela acessível pelo ícone de robô na AppBar da lista de viagens. É um chat
simples implementado com o pacote **flutter_bloc** só para demonstrar o
padrão Bloc em ação, seguindo a arquitetura View → Bloc → Provider:

- **View** ([`chat_bot_screen.dart`](lib/screens/chat_bot_screen.dart)): a
  tela de chat. Quando o usuário envia uma pergunta, chama
  `context.read<ChatBotBloc>().add(PerguntaEnviada(...))`.
- **Bloc** ([`chat_bot_bloc.dart`](lib/blocs/chat_bot_bloc.dart)): recebe o
  evento, repassa a pergunta para o Provider e dá `emit` do novo estado com
  o histórico atualizado. O Bloc **nunca** busca a dica sozinho.
- **Provider** ([`chat_bot_provider.dart`](lib/blocs/chat_bot_provider.dart)):
  única camada que conhece a fonte dos dados — hoje sorteia de uma lista
  fixa de 10 itens; se um dia virasse uma chamada de internet, seria só
  trocar a implementação deste arquivo, sem mexer no Bloc.

O texto da pergunta não influencia a resposta — é só para ilustrar o fluxo
completo View → Bloc (add Evento / emit Estado) → Provider.

## Foto da viagem

No cadastro/edição é possível escolher uma foto de capa pela galeria
([`foto_viagem_service.dart`](lib/services/foto_viagem_service.dart)). A
imagem precisa ser quadrada e ter no máximo 1000x1000 pixels — se não for,
o app pede para escolher outra. Depois de validada, ela é convertida para
base64 e salva direto no campo `fotoBase64` do documento da viagem (sem usar
Firebase Storage, para não precisar configurar mais um serviço). Essa foto
aparece como miniatura em cada card da lista principal.

O quadrado onde a foto é escolhida usa um `AnimatedContainer`: ao selecionar
uma imagem, ele anima suavemente o tamanho (120→140), a cor de fundo (some
o placeholder colorido) e o `borderRadius` (fica mais arredondado) — a
mesma ideia de transição de estilo vista em aula.

## Mapa do destino

O mapa usado em [`widgets/mapa_destino.dart`](lib/widgets/mapa_destino.dart) é
uma imagem estática (`assets/images/world_map_grey.png`) com um pin vermelho
posicionado por cálculo a partir da latitude/longitude salva. Essa imagem usa
projeção equirretangular (retangular, sem distorção de forma), então a
conversão linear de latitude/longitude para posição na tela é exata em
qualquer ponto do mapa.


## Como rodar o projeto

1. Instale as dependências:
   ```bash
   flutter pub get
   ```
2. Rode no Chrome (mais fácil para ver os logs do dio no console):
   ```bash
   flutter run -d chrome
   ```
   Ou em um simulador iOS/Android.

O projeto já vem com o Firebase configurado (`lib/firebase_options.dart`,
gerado pelo `flutterfire configure`). Se for clonar em outra máquina com outro
projeto Firebase, rode `flutterfire configure` novamente.

### Dados de exemplo

Na tela de lista, **toque e segure o botão +** (canto inferior direito) para
cadastrar automaticamente 3 viagens de exemplo (uma próxima, uma em
andamento e uma já concluída) — útil para testar rápido sem digitar tudo.

## Roteiro de demonstração (para a apresentação)

1. **Mostrar a lista vazia** e tocar e segurar o botão **+** para popular as
   viagens de exemplo — já aparecem com os selos de status diferentes.
2. **Cadastrar uma viagem nova**: digitar uma cidade (ex: "Roma"), mostrar a
   lista de resultados vindos da API de geocodificação, selecionar uma opção
   e apontar que país/latitude/longitude foram preenchidos sozinhos.
   - Com o terminal visível, mostrar o log do `Dio` imprimindo a requisição
     HTTP e a resposta da API.
3. **Abrir o detalhe de uma viagem**: mostrar o mapa com o pin no destino.
4. **Adicionar uma compra de dólar** no controle de câmbio e mostrar o
   totalizador em reais e a barra de progresso do orçamento se atualizando.
5. **Editar as anotações do diário** direto na tela de detalhe.
6. **Arrastar uma viagem na lista** para mostrar a exclusão com confirmação,
   e apontar que a lista atualiza sozinha (Firestore em tempo real).
7. **Abrir o assistente de viagem** (ícone de robô na AppBar) e fazer duas
   perguntas diferentes, mostrando que a resposta é sempre uma dica
   aleatória — essa tela é a demonstração do Bloc.

## Licença da imagem do mapa

A imagem `assets/images/world_map_grey.png` é uma versão recolorida (cinza e
branco) do mapa "Blank Map of The World Equirectangular Projection.png",
de FelixCountryBalls163 (Wikimedia Commons, CC BY 4.0).
