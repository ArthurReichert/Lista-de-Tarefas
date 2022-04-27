import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

class Home extends StatefulWidget {
  const Home({ Key? key }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List _listaTarefas = [];
  Map<String, dynamic> _ultimaTarefaRemovida = Map();
  TextEditingController _controllerTarefa = TextEditingController();

  Future<File> _getFile() async{

    //Recupera o diretório
    final diretorio = await getApplicationDocumentsDirectory(); //Pega o diretorio do arquivo
    return File("${diretorio.path}/dados.json"); //caminho/dados.json //Define o caminho (nome do arquivo)

  }

  _salvarTarefa(){

    String textoDigitado = _controllerTarefa.text;

    Map<String, dynamic> tarefa = Map();
    tarefa["titulo"] = textoDigitado; //Captura oq o usuário digita e coloca em titulo
    tarefa["realizada"] = false; //Booleano, por padrão, falso

    setState(() {
      _listaTarefas.add(tarefa); //Configura a tarefa dentro da lista
    });

    _salvarArquivo(); //Salva o arquivo
    _controllerTarefa.text = ""; //Apaga o último texto digitado

  }

  _salvarArquivo() async{
    
    var arquivo =  await _getFile();
  
    //Salva a lista de tareas
    String dados = json.encode(_listaTarefas); //Converte tarefas em objeto json como String
    arquivo.writeAsString(dados); //Escreve como uma String

  }

  _lerArquivo() async{

    try{ 
      
      final arquivo = await _getFile();
      return arquivo.readAsString();

    }catch(e){

      return null;
    }

  }

  @override
  void initState() {
    super.initState();

    _lerArquivo().then( 
      (dados){
      setState(() {
          _listaTarefas = json.decode(dados);
        });
      } 
    );
  }

  Widget criarItemLista(context, index){

    final item = _listaTarefas[index]['titulo'] ?? '';

    return Dismissible(
      key: UniqueKey(), //Todas as chaves vão ter um valor único
      direction: DismissDirection.endToStart,
      onDismissed: (direction){

        //Recuperar o último item excluido
        _ultimaTarefaRemovida = _listaTarefas[index];

        //Remove item da lista
        _listaTarefas.removeAt(index);
        _salvarArquivo();

        //Snackbar (desfazer)
        final snackbar = SnackBar(
          //backgroundColor: Colors.green,
          content: Text("Tarefa removida!"),
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: "Desafazer", 
            onPressed: (){

              //Insere novamente item removido na lista
              setState(() { //Se usa o setState pois o _listaTarefas é atualizado
                _listaTarefas.insert(index, _ultimaTarefaRemovida); //Insere no lugar que estava
              });

              _salvarArquivo();

            }
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackbar); //Mostra a mensagem

      },
      background: Container(
        color: Colors.red,
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.delete,
              color: Colors.white,
            )
          ],
        ),
      ),
      child: CheckboxListTile(
        title: Text(_listaTarefas[index]['titulo'] ?? ''), //Título
        value: _listaTarefas[index]['realizada'], 
        onChanged: (valorAlterado){
          setState(() { //Pressionando o checkbox, altera o valor de true pra false e vice versa
            _listaTarefas[index]['realizada'] = valorAlterado; 
          });
    
          _salvarArquivo(); //Salva no arquivo
                      
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    //_salvarArquivo(); 

    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.purple,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.purple,
        onPressed: (){
          showDialog(
            context: context, 
            builder: (context){
              return AlertDialog(
                title: Text("Adicionar Tarefa"),
                content: TextField(
                  controller: _controllerTarefa,
                  decoration: InputDecoration(
                    labelText: "Digite sua tarefa"
                  ),
                  onChanged: (text){},
                ),
                actions: [
                  TextButton(
                    child: Text("Cancelar"),
                    onPressed: () => Navigator.pop(context), 
                  ),
                  TextButton(
                    child: Text("Salvar"),
                    onPressed: (){

                      //Salvar
                      _salvarTarefa(); //Salva a tarefa dentro do arquivo

                      Navigator.pop(context);
                    }, 
                  )
                ],
              );
            }
          );
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _listaTarefas.length,
              itemBuilder: criarItemLista,
            )
          )
        ],
      ),
    );
  }
}