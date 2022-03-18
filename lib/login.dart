import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'main.dart';
import 'models/integrante.dart';
import 'utils/app_data.dart';
import 'utils/medidas.dart';
import 'utils/mensagens.dart';
import 'utils/utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /* VARIAVEIS */
  final _formKey = GlobalKey<FormState>();
  final _formUsuario = TextEditingController();
  final _formSenha = TextEditingController();

  /* WIDGETS */
  Widget get _cabecalho {
    return Column(
      children: const [
        Image(
          image: AssetImage('assets/images/login.png'),
          height: 256,
          width: 256,
        ),
        Text(
          AppData.appName,
          style: TextStyle(
            fontSize: 40,
            fontFamily: 'Offside',
          ),
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
        Text(
          AppData.version,
          style: TextStyle(color: Colors.grey),
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ],
    );
  }

  /* METODOS */

  /// Validar Formulário
  bool _validarFormulario() {
    if (_formKey.currentState == null) return false;
    return _formKey.currentState!.validate();
  }

  /// Logar no sistema
  void _logar() async {
    if (!_validarFormulario()) return;
    // Abre circulo de progresso
    Mensagem.aguardar(context: context, mensagem: 'Entrando...');
    // Tenta acessar a conta
    try {
      final credential = await auth.signInWithEmailAndPassword(
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
            .then((DocumentSnapshot<Integrante> documentSnapshot) {
          // Fecha progresso
          Navigator.pop(context);
          // Diacono registrado vai para home page
          if (documentSnapshot.exists) {
            integranteLogado = documentSnapshot.data();
            Modular.to.navigate('/');
          }
          // Diacono novo cria registro
          else {
            // Abre circulo de progresso
            Mensagem.aguardar(
                context: context, mensagem: 'Criando novo integrante...');
            Integrante integrante = Integrante(
              ativo: true,
              nome: user.displayName ?? user.email!,
              email: user.email!,
            );
            try {
              FirebaseFirestore.instance
                  .collection(Integrante.collection)
                  .doc(user.uid)
                  .set(integrante.toJson())
                  .then((value) {
                Navigator.pop(context); // Fecha progresso
                Modular.to.navigate('/integrante?id=' + user.uid);
              }).catchError((error) {
                dev.log("Falha ao criar novo perfil de integrante: $error",
                    name: 'DiaconoPage');
                Navigator.pop(context); // Fecha progresso
                // Ao falhar abre dialogo
                Mensagem.simples(
                    context: context,
                    titulo: 'Erro',
                    mensagem: 'Não foi possível criar o perfil');
              });
            } catch (e) {
              dev.log(e.toString(), name: 'LoginPage');
              Navigator.pop(context); // Fecha progresso
              // Ao falhar abre dialogo
              Mensagem.simples(
                  context: context,
                  titulo: 'Erro',
                  mensagem: 'Não foi possível criar o perfil');
            }
          }
        });
        return;
      }
    } catch (e) {
      dev.log(e.toString(), name: 'LoginPage');
    }
    Navigator.pop(context); // Fecha progresso
    // Ao falhar abre dialogo
    Mensagem.simples(
        context: context,
        titulo: 'Erro',
        mensagem:
            'Verifique seu usuário e senha.\n\nApenas usuários previamente cadastrados podem acessar o sistema');
  }

  /// Esqueci minha senha
  Future<void> _esqueciSenha() async {
    // Valida string e-mail
    if (Input.validarEmail(_formUsuario.text) != null) {
      _validarFormulario();
      return;
    }
    // Abre circulo de progresso
    Mensagem.aguardar(
        context: context, titulo: 'Aguarde', mensagem: 'Verificando e-mail...');
    try {
      await auth.sendPasswordResetEmail(email: _formUsuario.text);
      Navigator.pop(context); // fecha progresso
      // Abre mensagem de sucesso
      Mensagem.simples(
          context: context,
          titulo: 'Sucesso',
          mensagem:
              'Verifique a sua caixa de entrada para redefinir a sua senha!');
    } catch (e) {
      Navigator.pop(context); // fecha progresso
      // Abre mensagem de erro
      Mensagem.simples(
          context: context,
          titulo: 'Falha',
          mensagem:
              'Não foi possível localizar o email ${_formUsuario.text} em nosso cadastro!');
    }
  }

  /* METODOS DO SISTEMA */
  @override
  void dispose() {
    _formUsuario.dispose();
    _formSenha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: Center(
          child: Scrollbar(
            isAlwaysShown: true,
            showTrackOnHover: true,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Medidas.margemV(context),
                  horizontal: Medidas.margemH(context),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runAlignment: WrapAlignment.center,
                    runSpacing: 32,
                    spacing: 32,
                    children: [
                      // LOGOTIPO
                      _cabecalho,
                      ConstrainedBox(
                        constraints:
                            const BoxConstraints(minWidth: 200, maxWidth: 450),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.disabled,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // USUARIO
                              TextFormField(
                                controller: _formUsuario,
                                validator: Input.validarEmail,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.deny(' '),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  prefixIcon: Icon(Icons.email_rounded),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              // SENHA
                              TextFormField(
                                controller: _formSenha,
                                validator: Input.validarSenha,
                                obscureText: true,
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                enableSuggestions: false,
                                decoration: const InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: Icon(Icons.password_rounded),
                                ),
                                onFieldSubmitted: (_) => _logar(),
                              ),
                              const SizedBox(height: 24.0),
                              // BOTAO ENTRAR
                              ElevatedButton.icon(
                                icon: const Icon(Icons.login_rounded),
                                label: const Text('ENTRAR'),
                                onPressed: _logar,
                              ),
                              const SizedBox(height: 24.0),
                              // BOTAO ESQUECI SENHA
                              TextButton(
                                child: const Text(
                                  'Esqueci minha senha',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: _esqueciSenha,
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
          ),
        ),
      ),
    );
  }
}


// const MyHomePage(title: 'Escala do Louvor'),