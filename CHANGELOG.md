# Changelog

Todas as mudanças relevantes deste projeto são documentadas aqui. As entradas abaixo desta linha são
escritas pelo release-please (Conventional Commits → SemVer por impacto — ver ADR-019). Não editar à mão.

## [2.2.0](https://github.com/tuyoshivinicius/zion-build-prd/compare/v2.1.0...v2.2.0) (2026-07-24)


### Features

* **tools:** abortar quando a sentinela vaza para dentro do spec ([4ecb5ed](https://github.com/tuyoshivinicius/zion-build-prd/commit/4ecb5ed17b99b644da7b7705ecc60edd15b8e923))
* **tools:** classificação do turno + --self-test com fixtures da skill ([f070293](https://github.com/tuyoshivinicius/zion-build-prd/commit/f0702933273797d2295ddfde27ff142363b75bab))
* **tools:** classificador do analyze (primeiro corte, coberto por fixtures) ([a44886c](https://github.com/tuyoshivinicius/zion-build-prd/commit/a44886ce3f5c3dddb52ff05207cfcacd6a023db4))
* **tools:** cola do monitor (perfil por TTY, dois destinos, --quiet) ([72249a1](https://github.com/tuyoshivinicius/zion-build-prd/commit/72249a177fa786e46c1c5be502069dd45eac862a))
* **tools:** coleta de sensores contra o snapshot da rodada ([fac8166](https://github.com/tuyoshivinicius/zion-build-prd/commit/fac8166983f6f5f8b4a038b99712cac02deafcd5))
* **tools:** custo acumulado, teto de custo e teto de gate (puro) ([634602e](https://github.com/tuyoshivinicius/zion-build-prd/commit/634602e5081524fa44e0208b4b5693d72c555fd2))
* **tools:** custo por linha e linha de sensores como funções puras ([04bebb8](https://github.com/tuyoshivinicius/zion-build-prd/commit/04bebb804f4d0742c84638cbeebf21d5c1b9c34d))
* **tools:** dispara o aviso de suficiência no fundo do laço (R-3) ([8ff6c25](https://github.com/tuyoshivinicius/zion-build-prd/commit/8ff6c2587567c8199b27f5af8247585e33e443cb))
* **tools:** driver do loop (parada em camadas, dry-run e resumo final) ([2a6eaf5](https://github.com/tuyoshivinicius/zion-build-prd/commit/2a6eaf58c91d7e02ef41c4527f6303d4c32f720b))
* **tools:** e2e-loop cria a branch de feature do feature.json (Spec Kit branch-by-hook) ([60f678a](https://github.com/tuyoshivinicius/zion-build-prd/commit/60f678aa28f302fee90f5334ae50c8343f5da5a9))
* **tools:** e2e-loop detecta e traduz a convenção de comando do Spec Kit (dot/hyphen) ([72b465f](https://github.com/tuyoshivinicius/zion-build-prd/commit/72b465fe2a8371e18caff35ae17f0c817c615aa7))
* **tools:** esqueleto do speckit-clarify-loop (flags + checagem de dependências) ([4617426](https://github.com/tuyoshivinicius/zion-build-prd/commit/46174268988b53aa3f7aacf1127433cade208b73))
* **tools:** esqueleto do speckit-e2e-loop (deps, flags, self-test) ([063e959](https://github.com/tuyoshivinicius/zion-build-prd/commit/063e9594112b42324b271a2bd001acf01f2a06f1))
* **tools:** estado, retomada idempotente e limpeza do --from (puro) ([05d0775](https://github.com/tuyoshivinicius/zion-build-prd/commit/05d0775ff3125c34e934c536a33e6c6d6c02ed61))
* **tools:** fechar todo resumo com a linha revisar ([36208db](https://github.com/tuyoshivinicius/zion-build-prd/commit/36208dbdb7326590124529de9d53a158a3a83e48))
* **tools:** kind info (ⓘ/[nota]) para o aviso de suficiência (R-2) ([b5b2a9c](https://github.com/tuyoshivinicius/zion-build-prd/commit/b5b2a9ceb5a1b360f882f5a4a2fa940ce84a0668))
* **tools:** leitores de extração e sinal do file-drop (puro) ([8eca1d3](https://github.com/tuyoshivinicius/zion-build-prd/commit/8eca1d3f57a161640fc26a902416229b69f41bf1))
* **tools:** leitura de eventos do stream para o monitor do loop ([a19109c](https://github.com/tuyoshivinicius/zion-build-prd/commit/a19109c6b1503dd0adde5e3471f926e38dfc7242))
* **tools:** máquina de estados dos 8 passos (puro) ([658550f](https://github.com/tuyoshivinicius/zion-build-prd/commit/658550f22f1153ddc658cc064e05d406c95b4f80))
* **tools:** monitor (copiado do clarify) e motor de sessão run_step ([aaa96f4](https://github.com/tuyoshivinicius/zion-build-prd/commit/aaa96f44ecdf6c8d230ae1ec791de485074cde74))
* **tools:** motor da rodada narrando cada evento do stream ([85d0dc5](https://github.com/tuyoshivinicius/zion-build-prd/commit/85d0dc58015c2dcf9cbec0cc379528aa9d242194))
* **tools:** motor de rodada do loop (stream-json por FIFO, injeção de yes, abortos) ([94ea5d7](https://github.com/tuyoshivinicius/zion-build-prd/commit/94ea5d784d1068a0f86768a8bf0f811eb1ea0fb5))
* **tools:** narrar a ausência de sentinela sem abortar a rodada ([7aaa77c](https://github.com/tuyoshivinicius/zion-build-prd/commit/7aaa77caa6ffca8b74e6e7c8b6d4be4c58f7cd9a))
* **tools:** nudge_note e 4 casos de auto-teste (R-1) ([5aada2b](https://github.com/tuyoshivinicius/zion-build-prd/commit/5aada2ba3ac97b5c2a5c85ff4b95760a187353d0))
* **tools:** passo de clarify delega ao speckit-clarify-loop (rc→outcome) ([5705d23](https://github.com/tuyoshivinicius/zion-build-prd/commit/5705d2361def6e9d2521607bae755a9e3667f38b))
* **tools:** passo de trace reconcilia o canon (one-shot) ([47c9a8e](https://github.com/tuyoshivinicius/zion-build-prd/commit/47c9a8ef99da53b79c32943d8b53b45216e5d8d5))
* **tools:** passos de ponte — file-drop, gate auto-confirma, SUFFICIENCY_STOP ([75b85d5](https://github.com/tuyoshivinicius/zion-build-prd/commit/75b85d5d9f3e99d11ffaa59a7caa79e6851e5b5d))
* **tools:** passos de Spec Kit (injeção, one-shot, allowedTools por tipo) ([f147da3](https://github.com/tuyoshivinicius/zion-build-prd/commit/f147da397719c86e8d6121c82a51eaca8f06d817))
* **tools:** preflight do loop (repo Spec Kit, tree limpo, spec alvo via check-prerequisites) ([cdb5f6a](https://github.com/tuyoshivinicius/zion-build-prd/commit/cdb5f6a06246136d3cfa1647bbaca2c1d30d5e09))
* **tools:** preflight, driver do laço, parada-por-achado e resumo ([d0b4319](https://github.com/tuyoshivinicius/zion-build-prd/commit/d0b4319d70abe5c471adb7412cad8b606914f1c3))
* **tools:** primitivas de formatação do monitor (perfis, dobra, resumo de tool) ([7efd0a6](https://github.com/tuyoshivinicius/zion-build-prd/commit/7efd0a6765965ceb559a29fafe82e275e19372c2))
* **tools:** print_summary emissor único + summary.txt teado (R-3) ([cbe1e79](https://github.com/tuyoshivinicius/zion-build-prd/commit/cbe1e79785061961e7e93e0c47abc8c5a8fae7dc))
* **tools:** registro incremental por rodada em rounds.txt (R-2) ([7ac01ae](https://github.com/tuyoshivinicius/zion-build-prd/commit/7ac01ae200b60a7ad02690db855c596a680ebccd))
* **tools:** renderizador de eventos do monitor do loop ([c700135](https://github.com/tuyoshivinicius/zion-build-prd/commit/c7001350c5c371ac43d3adc94c1ec1c749b86b45))
* **tools:** resolução do check-prd.sh e detecção de vazamento de stack ([bde0303](https://github.com/tuyoshivinicius/zion-build-prd/commit/bde0303ab314e27d205388edb607103d188569b8))
* **tools:** resumir no fim da execução as decisões que o modelo aceitou ([2beb6b7](https://github.com/tuyoshivinicius/zion-build-prd/commit/2beb6b7f857f7c071f107279ce93cd1d155dc034))
* **tools:** rodapé do resumo cita rounds.txt e summary.txt (R-4) ([92001c6](https://github.com/tuyoshivinicius/zion-build-prd/commit/92001c6e78127557b9a344ac639caa958d3007d6))
* **tools:** round_record e 4 casos de auto-teste (R-1) ([b0ed861](https://github.com/tuyoshivinicius/zion-build-prd/commit/b0ed8610593c4523415aa26a6391c21c8f068a06))
* **tools:** sentinela de estado como contrato de saída da rodada ([2b73bac](https://github.com/tuyoshivinicius/zion-build-prd/commit/2b73bacdadf7df6d3591e2124998ea553023d871))
* **tools:** snapshot por rodada e narração dos sensores ([33a6f6a](https://github.com/tuyoshivinicius/zion-build-prd/commit/33a6f6aa99e2df54d33478a58f8f9653a51fa389))
* **tools:** sondar o estado em vez de abortar no turno sem sentinela ([fc7b753](https://github.com/tuyoshivinicius/zion-build-prd/commit/fc7b75309425b887911470fe408da43ed7324e6d))
* **tools:** um diretório de log por execução, com symlink latest ([04d42c5](https://github.com/tuyoshivinicius/zion-build-prd/commit/04d42c5bbd4a9402f24ba3a418d0d3bc6707b114))


### Bug Fixes

* **tools:** --dry-run captura o file-drop sem tocar o repo ([fb5824d](https://github.com/tuyoshivinicius/zion-build-prd/commit/fb5824d212a72ca562b52eec1d555fd3d7ca5152))
* **tools:** abortar só quando a negação for de ferramenta que escreve ([03dcc1f](https://github.com/tuyoshivinicius/zion-build-prd/commit/03dcc1f9da9357f3340b21f586175ca4da51a3ac))
* **tools:** classificar a pergunta em pt no feminino ([0251111](https://github.com/tuyoshivinicius/zion-build-prd/commit/02511111a3d9288d8157abc25f1ca8a888e1b185))
* **tools:** custo da rodada é o último total_cost_usd, não a soma ([805dd0b](https://github.com/tuyoshivinicius/zion-build-prd/commit/805dd0be74b6677edc0b920190207109cedf298a))
* **tools:** fechar rodada por regex ancorada e tolerar allowed_* ([c9379ba](https://github.com/tuyoshivinicius/zion-build-prd/commit/c9379ba72e6554866ed2c87b5e58599f62291a48))
* **tools:** file-drop escreve no scratch via --add-dir (confirmado pago) ([0ea3406](https://github.com/tuyoshivinicius/zion-build-prd/commit/0ea340647d5eeffe886bc6872d913aa2001adef5))
* **tools:** P-7 silencia erro de escrita com $LOG_DIR removido + polimentos de review ([c0a5ef0](https://github.com/tuyoshivinicius/zion-build-prd/commit/c0a5ef085da8e9a180de0e26ed4c7228c00e8cf0))
* **tools:** reconhecer o Completion Report titulado "Próximo passo" ([dc3ac95](https://github.com/tuyoshivinicius/zion-build-prd/commit/dc3ac95ab91bf105e889c7e29840f2698df60adc))
* **tools:** run_step declara err/in em locals separados (set -u) ([350ef06](https://github.com/tuyoshivinicius/zion-build-prd/commit/350ef06adb92007e12338ee5ad37a271d1e5d4fa))
* **tools:** subir o teto de tempo da rodada para 1800 s ([3acf3df](https://github.com/tuyoshivinicius/zion-build-prd/commit/3acf3dfa42d395ace0fa9d8f399b68affada8cc5))

## [2.1.0](https://github.com/tuyoshivinicius/zion-build-prd/compare/v2.0.0...v2.1.0) (2026-07-21)


### Features

* **adr:** area-ausente advisório e Área pedida pelo /zion-adr-new ([bd3af72](https://github.com/tuyoshivinicius/zion-build-prd/commit/bd3af7244f2ca3721b80bd8d795c8a6aa2576c8e))
* **ajuda:** skill /zion-prd-ajuda com grounding vivo + canonização (RF-19, E7) ([45e467f](https://github.com/tuyoshivinicius/zion-build-prd/commit/45e467f869ad39861ce86a3ce32fe1ac26a6a490))
* **arquitetura:** a §3 vira mapa de decisões por área com fixou e specs ([e87e7f2](https://github.com/tuyoshivinicius/zion-build-prd/commit/e87e7f2f641d438050a84269a089401bd54d5d86))
* **arquitetura:** achados de narrativa/integrações e esqueleto com blocos ditados ([ce608a5](https://github.com/tuyoshivinicius/zion-build-prd/commit/ce608a5231d857c442b1fd2ee0c9ea5657a84057))
* **arquitetura:** bloco de avisos da narrativa reconciliado pelo trace ([a8aaec9](https://github.com/tuyoshivinicius/zion-build-prd/commit/a8aaec98511d03d4ffd7bacd4fae54f443f5b16a))
* **canon:** regra C8 — citações da skill de ajuda não envelhecem ([3c741d5](https://github.com/tuyoshivinicius/zion-build-prd/commit/3c741d5d4a988fb9bc74772cedcec6f4f32bbb02))
* **decompose:** fase de narrativa estrutural sob ditado e flag --narrativa ([4ed7562](https://github.com/tuyoshivinicius/zion-build-prd/commit/4ed75624e87538374fc310edabba4323c601c84b))
* **delegacao:** fase de delegação classificada em discovery/write/decompose ([f973add](https://github.com/tuyoshivinicius/zion-build-prd/commit/f973add3360cd10c64e16687e3d933b133e73abf))
* **delegacao:** gate check-delegacao.sh + auto-teste e fixtures (NFR-04) ([c16e55b](https://github.com/tuyoshivinicius/zion-build-prd/commit/c16e55b9ae58ff737f69835b56e6744d80703599))
* **delegacao:** rubrica de fonte única da delegação criativa classificada ([ef43ca1](https://github.com/tuyoshivinicius/zion-build-prd/commit/ef43ca15e751c3c13a7f0c8e076d0abbfa0e8b10))
* **pontes:** rota de narrativa defasada no dia 2 e plan lendo a narrativa pelo marcador ([44124ba](https://github.com/tuyoshivinicius/zion-build-prd/commit/44124ba203ae9e0bf70c662e04737977657c9270))
* **release:** CD por release-PR automatizado por impacto (RF-21 / ADR-019) ([c65988b](https://github.com/tuyoshivinicius/zion-build-prd/commit/c65988b0f63b7dcd9ff9bbafca3ed5473ac7d573))
* **release:** commit-lint de Conventional Commits em shell + auto-teste (NFR-04) ([2e3a6e4](https://github.com/tuyoshivinicius/zion-build-prd/commit/2e3a6e471721935a6a46a5e33c5e4cdaa4153b9c))
* **release:** release-PR automatizado via release-please (RF-21) ([f5a2511](https://github.com/tuyoshivinicius/zion-build-prd/commit/f5a2511db2f80f80d85328d4f9a302ac6b1a8480))

## [2.0.0] — histórico pré-automação

- Distribuição dual (plugin do Claude Code + skills.sh) por cópia real (ADR-002).
