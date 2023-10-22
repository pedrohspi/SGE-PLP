:- initialization (main).

%Comando pra rodar 
% swipl -s main.pl

% Inclusão da base de dados
:- consult('DataBase/gerenciadorGeral.pl').
:- consult('DataBase/gerenciadorAluno.pl').
:- consult('DataBase/gerenciadorGrupo.pl').

:- consult('constantes.pl').

:- include('aluno.pl').
:- include('grupo.pl').

% Inclusão dos utilitários
:- consult('utils.pl').
:- encoding(utf8).
:- set_prolog_flag(encoding, utf8).
:- use_module(library(http/json)).
:- use_module(library(date)).
:- use_module(library(random)).


:- encoding(utf8).
:- set_prolog_flag(encoding, utf8).

%Recebe os dados do usuário
prompt(Message, String):-
    write(Message),
    flush_output,
    read_line_to_codes(user_input, Codes),
    string_codes(String, Codes).

main:-
    writeln( '\n =========== Olá! Seja bem vindo ao SGE: Sistema de Gerenciamento de Estudos :D ===========\n'),
    write('\n Escolha uma opção para começar a navegar no sistema: \n'),
    write('1. Login\n'),
    write('2. Cadastrar\n'),
    write('3. Sair\n'),
    prompt('->', Input),
    atom_number(Input, Opcao),
    write('\n'),
    opSelecionada(Opcao).

opSelecionada(1):-
    menuLogin,
    main.

opSelecionada(2):-
    menuCadastro,
    main.
    
opSelecionada(3):-
    write('Saindo...\n'),
    halt.

opSelecionada(_):-
    write('Ops! Entrada Invalida...\n'),
    main.

%Menu responsável por fazer o login
menuLogin:-
    prompt('Matrícula: ', Matricula),
    (verificaLogin(Matricula) ->
        prompt('Senha: ', Senha),
        (verificaSenhaAluno(Matricula, Senha) ->
            menuInicial(Matricula)
        ;
            write('Senha incorreta, tente novamente. \n'),
            menuLogin)
    ;
        write('Aluno não encontrado!'), 
        menuEscolhaLogin
    ).


menuEscolhaLogin:-
    write('\nEscolha uma opção para seguir\n'),
    write('1. Fazer login \n'),
    write('2. Fazer cadastro\n'),
    write('3. Sair\n'),
    prompt('->', Input),
    atom_number(Input, Opcao),
    write('\n'),
    verificaEscolha(Opcao).

verificaEscolha(1):-
    menuLogin.

verificaEscolha(2):-
    menuCadastro.

verificaEscolha(3):-
    write('Saindo...\n'),
    halt.

verificaEscolha(_):-
    write('Opção inválida'),
    menuEscolhaLogin.

%Menu resonsável por fazer o cadastro 
menuCadastro :-
    prompt('Matrícula: ', Matricula),
    prompt('Nome: ', Nome),
    prompt('Senha: ', Senha),
    cadastraAluno(Matricula, Nome, Senha, ResultParcial),
    (ResultParcial = 'ok' -> 
        write('Aluno Cadastrado'),
        menuInicial(Matricula)
        ;
        write('Não foi possível fazer o cadastro'),
        menuEscolhaLogin).


% Menu para mostra as opções do SGE para o usuário.
menuInicial(Matricula):-
    writeln('\nEscolha uma opção:\n'),
    write('1. Criar grupo\n'),
    write('2. Remover grupo\n'),
    write('3. Meus grupos\n'),
    write('4. Minhas disciplinas\n'),
    write('5. Procurar Grupo\n'),
    write('6. Sair\n'),
    prompt('->', Input),
    atom_number(Input, Opcao),
    write('\n'),
    selecaoMenuInicial(Opcao, Matricula).

%Criar grupo
selecaoMenuInicial(1, Matricula):-
    writeln('\n==Cadastrando Grupo==\n'),
    prompt('Código do grupo: ', CodGrupo),
    prompt('Nome do grupo: ', NomeGrupo),
    cadastraGrupo(CodGrupo, NomeGrupo, Matricula, Result),
    (Result = 'ok' ->
        write('Grupo Cadastrado'),
        menuInicial(Matricula)
    ;
        write('Já existe um grupo com esse ID. Cadastre um grupo novo!\n'),
        menuInicial(Matricula)
    ). 


%Remover grupo
selecaoMenuInicial(2, Matricula):-
    writeln('\n==Removendo Grupo==\n'),
    prompt('Código do grupo: ', CodGrupo),
    verificaAdm(CodGrupo, Matricula, Result1),
    (Result1 = 1 ->
        (removeGrupo(CodGrupo, Matricula) ->
            write('Grupo removido'),
            menuInicial(Matricula)
        ;
            write('Grupo não encontrado'),
            menuInicial(Matricula)
        )
    ;
        write('Não é administrador do grupo e não pode remover'),
        menuInicial(Matricula)
    ).


%Acessando grupos
selecaoMenuInicial(3, Matricula):-
    menuMeusGrupos(Matricula).

    %menuInicial(Matricula).

selecaoMenuInicial(4, Matricula):-
    menuMinhasDisciplinas(Matricula).
    %menuInicial(Matricula).

%Listagem de grupos em comum
selecaoMenuInicial(5, Matricula):-
    listagemGruposEmComum(Matricula, Result),
    write(Result),
    menuInicial(Matricula).

%Voltando para o menu
selecaoMenuInicial(6, _):-
    write('Saindo...\n'),
    halt.

selecaoMenuInicial(_, Matricula):-
    write('Opção inválida'),
    menuInicial(Matricula).


%Menu específico para as funções dos grupos.
menuMeusGrupos(Matricula):-
    writeln('\nEscolha o que você quer fazer\n'),
    write('1. Adicionar Aluno\n'),
    write('2. Remover Aluno\n'),
    write('3. Visualizar Alunos\n'),
    write('4. Adicionar Disciplina\n'),
    write('5. Visualizar Disciplina\n'),
    write('6. Remover Disciplina\n'),
    write('7. Acessar Materiais\n'),
    write('8. Ver grupos\n'),
    write('9. Voltar\n'),
    prompt('->', Input),
    atom_number(Input, Opcao),
    write('\n'),
    selecaoMenuMeusGrupos(Opcao, Matricula).


    %Adicionar aluno
    selecaoMenuMeusGrupos(1, Matricula):-
        prompt('Matrícula do aluno a ser adicionado: ', MatriculaAluno),
        prompt('Código do grupo: ', CodGrupo),
        verifica_adm(CodGrupo, Matricula, R),
        (R = 1 -> adiciona_aluno_grupo(MatriculaAluno, CodGrupo, Result), write(Result);
        write('Não é Adm do grupo')),
        menuMeusGrupos(Matricula).

     %Remover aluno
    selecaoMenuMeusGrupos(2, Matricula):-
        prompt('Matrícula do aluno a ser removido: ', MatriculaAluno),
        prompt('Código do grupo: ', CodGrupo),
        verifica_adm(CodGrupo, Matricula, R),
        (R = 1 -> remove_aluno_grupo(Matricula, MatriculaAluno, CodGrupo, Result), write(Result);
        write('Não é Adm do grupo')),
        menuMeusGrupos(Matricula).

    %Visualizar Alunos
    selecaoMenuMeusGrupos(3, Matricula):-
        prompt('Código do grupo para listar os alunos: ', CodGrupo),
        listagem_alunos_grupo(CodGrupo, Result),
        write(Result),
        menuMeusGrupos(Matricula).

    %Adicionar Disciplina
    selecaoMenuMeusGrupos(4, Matricula):-
        prompt('Código do grupo: ', CodGrupo),
        prompt('Código da disciplina que você quer adicionar: ', IdDiscilina),
        prompt('Nome da disciplina: ', NomeDiscilina),
        prompt('Nome do professor: ', NomeProfessor),
        prompt('Período: ', Periodo),
        cadastraDisciplinaGrupo(CodGrupo, IdDiscilina, NomeDiscilina, NomeProfessor, Periodo, Result),
        write(Result),
        menuMeusGrupos(Matricula).

    %Visualizar Disciplina
    selecaoMenuMeusGrupos(5, Matricula):-
        prompt('Código do grupo: ', CodGrupo),
        listagemDisciplinaGrupo(CodGrupo, Result),
        write(Result),
        menuMeusGrupos(Matricula).

    %Remover Disciplina
    selecaoMenuMeusGrupos(6, Matricula):-
        prompt('Código da disciplina que você quer remover: ', IdDiscilina),
        prompt('Código do grupo: ', CodGrupo),
        removeDisciplinaGrupo(IdDiscilina, CodGrupo, Result),
        write(Result),
        menuMeusGrupos(Matricula).
   
    %Acessar Materiais
    selecaoMenuMeusGrupos(7, Matricula):-
        menuMateriaisGrupo (Matricula).
        %menuMeusGrupos(Matricula).
    
    %Ver grupos
    selecaoMenuMeusGrupos(8, Matricula):-
        write('\nEsses são os seus grupos: \n'),
        listagemGrupos(Matricula, Result),
        write(Result),
        menuMeusGrupos(Matricula).
   
    %Voltar para o menu inicial
    selecaoMenuMeusGrupos(9, Matricula):-
        menuInicial(Matricula).
    
    %Entrada inválida
    selecaoMenuMeusGrupos(_, Matricula):-
        write('Opção inválida'),
        menuMeusGrupos(Matricula).


menuMinhasDisciplinas(Matricula) :-
    write('\n1. Visualizar disciplinas\n'),
    write('2. Cadastrar disciplina\n'),
    write('3. Remover disciplina\n'),
    write('4. Materiais\n'),
    write('5. Voltar\n'),
    write('6. Sair\n'),
    prompt('----> ', Input),
    atom_number(Input, Opcao),
    write('\n'),
    opselecionadaDisciplinaAluno(Opcao, Matricula).

    
opselecionadaDisciplinaAluno(1, Matricula) :-
    exibe_disciplinas(Matricula,Result),
    write(Result),
    menuMinhasDisciplinas(Matricula).
    
opselecionadaDisciplinaAluno(2, Matricula) :-
    prompt('O código da disciplina que você quer cadastrar: ', Codigo),
    prompt('Nome da disciplina: ', Nome),
    prompt('Professor que ministra: ',Professor),
    prompt('Período: ', Periodo),
    cadastra_disciplina_aluno(Matricula, Codigo, Nome, Professor, Periodo, Result),
    write(Result),
    menuMinhasDisciplinas(Matricula).
    
opselecionadaDisciplinaAluno(3, Matricula) :-
    prompt('Código da disciplina que você quer remover: ', Codigo),
    rm_disciplina_aluno(Matricula, Codigo, Result),
    write(Result),
    menuMinhasDisciplinas(Matricula).
    
opselecionadaDisciplinaAluno(4, Matricula) :-
    menuMateriaisAluno(Matricula),
    menuMinhasDisciplinas(Matricula).
    
opselecionadaDisciplinaAluno(3, Matricula) :-
    menuMinhasDisciplinas(Matricula).
    
opselecionadaDisciplinaAluno(4, Matricula) :-
    menuMinhasDisciplinas(Matricula).
    
opselecionadaDisciplinaAluno(5, Matricula) :-
    menuInicial(Matricula).
    
    
opselecionadaDisciplinaAluno(6, Matricula) :-
    write('Saindo...'), 
    halt.

opselecionadaDisciplinaAluno(_,Matricula) :- write('Opcão inválida!'), menuMinhasDisciplinas(Matricula).


menuCadastraMateriaisAluno(Matricula) :-
    writeln('\nSelecione o tipo de material que você gostaria de cadastrar:\n'),
    write('1. Resumo\n'),
    write('2. Links\n'),
    write('3. Datas\n'),
    write('4. Voltar\n'),
    prompt('----> ', Input),
    atom_number(Input, Opcao),
    write('\n'),
    opselecionadaCadastraMateriaisAluno(Opcao, Matricula).


opselecionadaCadastraMateriaisAluno(1, Matricula) :-
    prompt('Código da disciplina: ', IdDisciplina),
    prompt('Nome do resumo: ', Nome),
    prompt('Conteúdo do resumo: ', Resumo),
    add_resumo_disciplina_aluno(Matricula, IdDisciplina, Nome, Resumo, Result),
    write(Result),
    menuCadastraMateriaisAluno(Matricula).

opselecionadaCadastraMateriaisAluno(2, Matricula) :-
    prompt('Código da disciplina: ', Codigo),
    prompt('Titulo: ', Titulo),
    prompt('Link: ', Link).

opselecionadaCadastraMateriaisAluno(3, Matricula) :-
    prompt('Código da disciplina: ', Codigo),
    prompt('Titulo: ', Titulo),
    prompt('Data início: ', DataI),
    prompt('Data fim: ', DataF).

opselecionadaCadastraMateriaisAluno(4, Matricula) :-
    menuMinhasDisciplinas(Matricula).

opselecionadaCadastraMateriaisAluno(_, Matricula):- 
    write('Opcão inválida!'),
    menuCadastraMateriaisAluno(Matricula).

menuMateriaisAluno(Matricula) :-
    writeln('\n1. Ver materiais'),
    writeln('2. Adicionar materiais'),
    writeln('3. Remover materiais'),
    writeln('4. Voltar'),
    writeln('5. Sair'),
    prompt('----> ', Input),
    atom_number(Input, Opcao),
    write('\n'),
    opselecionadaMateriaisAluno(Opcao, Matricula).

opselecionadaMateriaisAluno(1, Matricula):-
    menuMateriaisAluno(Matricula).

opselecionadaMateriaisAluno(2, Matricula):-
    menuCadastraMateriaisAluno(Matricula).

opselecionadaMateriaisAluno(3 Matricula):-
    menuMateriaisAluno(Matricula).

opselecionadaMateriaisAluno(4, Matricula):-
    menuMinhasDisciplinas(Matricula).

opselecionadaMateriaisAluno(5, Matricula):-
    write('Saindo...'), 
    halt.

opselecionadaMateriaisAluno(_, Matricula):- 
    write('Opcão inválida!'),   
    menuMateriaisAluno(Matricula).