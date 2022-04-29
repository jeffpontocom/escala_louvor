import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:escala_louvor/global.dart';
import 'package:escala_louvor/screens/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '/models/integrante.dart';
import '/utils/mensagens.dart';
import '/utils/utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              runAlignment: WrapAlignment.center,
              runSpacing: 32,
              spacing: 32,
              children: [
                // Cabeçalho
                Column(
                  children: [
                    // Logotipo
                    const Image(
                      image: AssetImage('assets/images/login.png'),
                      height: 256,
                      width: 256,
                    ),
                    // Nome do App
                    Text(
                      kIsWeb
                          ? 'Escala Louvor'
                          : Global.appInfo?.appName ?? '...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 40,
                        fontFamily: 'Offside',
                      ),
                    ),
                    // Versão do App
                    Text(
                      'versão ${Global.appInfo?.version ?? '...'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 200, maxWidth: 450),
                  // Formulário
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Campo Usuário
                        TextFormField(
                          controller: _formUsuario,
                          validator: MyInputs.validarEmail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email
                          ],
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.deny(' '),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 8.0),
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
                          onFieldSubmitted: (_) => _logar(),
                        ),
                        const SizedBox(height: 24.0),
                        // Botão Login
                        ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('ENTRAR'),
                          onPressed: _logar,
                        ),
                        const SizedBox(height: 24.0),
                        // Botão esqueci minha senha
                        TextButton(
                          child: const Text(
                            'Esqueci minha senha',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: _esqueciMinhaSenha,
                        ),
                      ],
                    ),
                  ),
                ),
                // Texto Informativo
                const SizedBox(
                  width: double.maxFinite,
                  child: Text(
                    'Apenas usuários cadastrados pelo administrador tem acesso ao sistema.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            // Integrante já registrado. Vai para home page
            Modular.to.navigate('/${Paginas.values[0].name}');
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
              // Sucesso. Vai para home
              Modular.to.navigate('/${Paginas.values[0].name}');
            } catch (e) {
              dev.log("Falha ao criar novo perfil de integrante: $e");
              Modular.to.pop(); // Fecha progresso
              // Falha. Abre dialogo
              Mensagem.simples(
                  context: context,
                  titulo: 'Erro',
                  mensagem: 'Não foi possível criar o perfil do integrante');
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
      titulo: 'Erro',
      mensagem: mensagemErro,
      /* mensagem:
          'Verifique seu usuário e senha.\n\nApenas usuários previamente cadastrados podem acessar o sistema.', */
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
          titulo: 'Sucesso',
          mensagem:
              'Verifique a sua caixa de entrada para redefinir a sua senha!');
    } catch (e) {
      Modular.to.pop(); // Fecha progresso
      // Abre mensagem de erro
      Mensagem.simples(
          context: context,
          titulo: 'Falha',
          mensagem:
              'Não foi possível localizar o email ${_formUsuario.text} em nosso cadastro!');
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

  ///
  /// Accepts AuthExceptionHandler.errorType
  ///
  static generateExceptionMessage(exceptionCode) {
    String errorMessage;
    switch (exceptionCode) {
      case AuthResultStatus.invalidEmail:
        errorMessage = "Seu endereço de e-mail parece estar incorreto.";
        break;
      case AuthResultStatus.wrongPassword:
        errorMessage = "Senha incorreta.";
        break;
      case AuthResultStatus.userNotFound:
        errorMessage =
            "O usuário com este e-mail não existe.\n\nApenas usuários previamente cadastrados podem acessar o sistema.";
        break;
      case AuthResultStatus.userDisabled:
        errorMessage =
            "O usuário com este e-mail foi desativado.\n\nApenas usuários ativos podem acessar o sistema.";
        break;
      case AuthResultStatus.tooManyRequests:
        errorMessage = "Muitos pedidos. Tente mais tarde novamente.";
        break;
      case AuthResultStatus.operationNotAllowed:
        errorMessage = "Entrar com e-mail e senha não está ativado.";
        break;
      case AuthResultStatus.emailAlreadyExists:
        errorMessage =
            "O e-mail já foi cadastrado.\n\nPor favor, faça o login ou redefina sua senha.";
        break;
      case AuthResultStatus.networkRequestFailed:
        errorMessage =
            "Ocorreu um erro de rede (como tempo limite, conexão interrompida ou host inacessível).\n\nVerifique sua conexão.";
        break;
      default:
        errorMessage = "Ocorreu um erro inesperado.";
    }
    return errorMessage;
  }
}
