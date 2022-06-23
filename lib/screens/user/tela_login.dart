import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '/models/integrante.dart';
import '/resources/medidas.dart';
import '/utils/global.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({Key? key}) : super(key: key);

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  /* VARIÁVEIS */
  final _formKey = GlobalKey<FormState>();
  final _formUsuario = TextEditingController();
  final _formSenha = TextEditingController();

  /* MÉTODOS DO SISTEMA */

  @override
  void dispose() {
    _formUsuario.dispose();
    _formSenha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(builder: (context, orientation) {
          var isPortrait = orientation == Orientation.portrait;
          var padding = Medidas.bodyPadding(context);
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  var space = 32.0;
                  return Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: space,
                    runSpacing: space,
                    children: [
                      // Cabeçalho
                      ConstrainedBox(
                        child: cabecalho,
                        constraints: BoxConstraints(
                            maxWidth: isPortrait
                                ? constraints.maxWidth
                                : constraints.maxWidth * 2 / 5),
                      ),
                      // Formulário
                      ConstrainedBox(
                        child: formularioLogin,
                        constraints: BoxConstraints(
                            maxWidth: isPortrait
                                ? constraints.maxWidth
                                : (constraints.maxWidth * 3 / 5) - space),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  /* WIDGETS */

  /// Cabeçalho (Column)
  get cabecalho {
    return Column(
      children: [
        // Ilustração
        const Image(
          image: AssetImage('assets/images/login.png'),
          height: 256,
          width: 256,
        ),
        // Nome do app
        const Text(
          'Escala do Louvor',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Offside',
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Versão
        Global.versaoDoAppText,
      ],
    );
  }

  /// Formulário de Login
  get formularioLogin {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: AutofillGroup(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo Usuário
              TextFormField(
                controller: _formUsuario,
                validator: MyInputs.validarEmail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.deny(' ')
                ],
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 12),
              // Campo Senha
              TextFormField(
                  controller: _formSenha,
                  validator: MyInputs.validarSenha,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: Icon(Icons.password),
                  ),
                  onFieldSubmitted: (_) {
                    _logar();
                  }),
              const SizedBox(height: 12),
              // Advertência
              advertencia,
              const SizedBox(height: 24),
              // Botão Login
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Entrar'),
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(172, 40)),
                onPressed: _logar,
              ),
              const SizedBox(height: 16),
              // Botão esqueci minha senha
              TextButton(
                onPressed: _esqueciMinhaSenha,
                child: const Text('Esqueci minha senha',
                    style: TextStyle(color: Colors.red)),
              ),
            ]),
      ),
    );
  }

  /// Advertência
  get advertencia {
    return const Text(
      'Apenas usuários cadastrados pelo administrador tem acesso ao sistema',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey),
    );
  }

  /* METODOS */

  /// Validar Formulário
  bool _validarForm() {
    if (_formKey.currentState == null) return false;
    return _formKey.currentState!.validate();
  }

  /// Logar no sistema
  void _logar() async {
    if (!_validarForm()) return;
    TextInput.finishAutofillContext();
    // Abre progresso
    Mensagem.aguardar(context: context, mensagem: 'Entrando...');
    var mensagemErro = '';
    // Tenta acessar a conta
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _formUsuario.text, password: _formSenha.text);
      if (credential.user != null) {
        User user = credential.user!;
        FirebaseFirestore.instance
            .collection(Integrante.collection)
            .doc(user.uid)
            .withConverter<Integrante>(
                fromFirestore: (snapshot, _) =>
                    Integrante.fromJson(snapshot.data()!),
                toFirestore: (pacote, _) => pacote.toJson())
            .get()
            .then((DocumentSnapshot<Integrante> documentSnapshot) async {
          Modular.to.pop(); // Fecha progresso
          if (documentSnapshot.exists) {
            // INTEGRANTE JÁ REGISTRADO
            // Persistir autenticação na web
            if (kIsWeb) {
              FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
            }
            // Vai para home page
            Modular.to.navigate(Global.rotaInicial);
          } else {
            // Cria novo registro de integrante
            // Abre progresso
            Mensagem.aguardar(
                context: context, mensagem: 'Criando novo integrante...');
            Integrante integrante = Integrante(
              ativo: true,
              nome: user.displayName ?? user.email!,
              email: user.email!,
            );
            try {
              await FirebaseFirestore.instance
                  .collection(Integrante.collection)
                  .doc(user.uid)
                  .set(integrante.toJson());
              // NOVO INTEGRANTE CRIADO
              // Persistir autenticação na web
              if (kIsWeb) {
                FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
              }
              // Vai para home
              Modular.to.navigate(Global.rotaInicial);
            } catch (e) {
              dev.log("Não foi possível criar o perfil do integrante: $e.");
              Modular.to.pop(); // Fecha progresso
              // Falha. Abre dialogo
              Mensagem.simples(
                  context: context,
                  titulo: 'Falhou!',
                  mensagem: 'Não foi possível criar o perfil do integrante.');
            }
          }
        });
        return;
      }
    } catch (e) {
      dev.log(e.toString());
      var status = AuthExceptionHandler.handleException(e);
      mensagemErro = AuthExceptionHandler.generateExceptionMessage(status);
    }
    Modular.to.pop(); // Fecha progresso
    // Ao falhar abre dialogo
    Mensagem.simples(
      context: context,
      titulo: 'Falhou!',
      mensagem: mensagemErro,
    );
  }

  /// Esqueci minha senha
  Future<void> _esqueciMinhaSenha() async {
    // Valida string e-mail
    if (MyInputs.validarEmail(_formUsuario.text) != null) {
      _validarForm();
      return;
    }
    // Abre progresso
    Mensagem.aguardar(
        context: context, titulo: 'Aguarde', mensagem: 'Verificando e-mail...');
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _formUsuario.text);
      Modular.to.pop(); // Fecha progresso
      // Abre mensagem de sucesso
      Mensagem.simples(
          context: context,
          titulo: 'Sucesso!',
          mensagem:
              'Verifique a sua caixa de entrada para redefinir a sua senha.');
    } catch (e) {
      Modular.to.pop(); // Fecha progresso
      // Abre mensagem de erro
      Mensagem.simples(
          context: context,
          titulo: 'Falha!',
          mensagem:
              'Não foi possível localizar o e-mail ${_formUsuario.text} em nosso cadastro.');
    }
  }
}

enum AuthResultStatus {
  successful,
  emailAlreadyExists,
  wrongPassword,
  invalidEmail,
  userNotFound,
  userDisabled,
  operationNotAllowed,
  tooManyRequests,
  networkRequestFailed,
  undefined,
}

class AuthExceptionHandler {
  static handleException(e) {
    dev.log(e.code);
    AuthResultStatus status;
    switch (e.code) {
      case "invalid-email":
        status = AuthResultStatus.invalidEmail;
        break;
      case "wrong-password":
        status = AuthResultStatus.wrongPassword;
        break;
      case "user-not-found":
        status = AuthResultStatus.userNotFound;
        break;
      case "user-disabled":
        status = AuthResultStatus.userDisabled;
        break;
      case "too-many-requests":
        status = AuthResultStatus.tooManyRequests;
        break;
      case "operation-not-allowed":
        status = AuthResultStatus.operationNotAllowed;
        break;
      case "email-already-exists":
        status = AuthResultStatus.emailAlreadyExists;
        break;
      case "network-request-failed":
        status = AuthResultStatus.networkRequestFailed;
        break;
      default:
        status = AuthResultStatus.undefined;
    }
    return status;
  }

  /// Accepts AuthExceptionHandler.errorType
  static generateExceptionMessage(exceptionCode) {
    String errorMessage;
    switch (exceptionCode) {
      case AuthResultStatus.invalidEmail:
        errorMessage = 'Seu endereço de e-mail parece estar incorreto.';
        break;
      case AuthResultStatus.wrongPassword:
        errorMessage =
            'Senha incorreta.\n\nTente novamente ou redefina sua senha.';
        break;
      case AuthResultStatus.userNotFound:
        errorMessage =
            'O usuário com este e-mail não existe.\n\nApenas usuários previamente cadastrados podem acessar o sistema.';
        break;
      case AuthResultStatus.userDisabled:
        errorMessage =
            'O usuário com este e-mail foi desativado.\n\nApenas usuários ativos podem acessar o sistema.';
        break;
      case AuthResultStatus.tooManyRequests:
        errorMessage = 'Muitos pedidos. Tente mais tarde novamente.';
        break;
      case AuthResultStatus.operationNotAllowed:
        errorMessage = 'Entrar com e-mail e senha não está ativado.';
        break;
      case AuthResultStatus.emailAlreadyExists:
        errorMessage =
            'O e-mail já foi cadastrado.\n\nPor favor, faça o login ou redefina sua senha.';
        break;
      case AuthResultStatus.networkRequestFailed:
        errorMessage =
            'Verifique sua conexão.\n\nOcorreu um erro de rede (como tempo limite, conexão interrompida ou host inacessível).';
        break;
      default:
        errorMessage = 'Ocorreu um erro inesperado.';
    }
    return errorMessage;
  }
}
