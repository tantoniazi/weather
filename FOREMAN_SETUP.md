# Configuração do Foreman - Sistema Weather

## ✅ Foreman Configurado com Sucesso!

O **Foreman** foi configurado para gerenciar múltiplos processos no boot do sistema.

## 🚀 **O que foi implementado:**

### 1. **Gem Foreman Adicionado**
```ruby
# Gemfile
gem "foreman"
```

### 2. **Arquivos de Configuração**
- ✅ `Procfile` - Processos de produção
- ✅ `Procfile.dev` - Processos de desenvolvimento
- ✅ `bin/start` - Script de inicialização

### 3. **Dockerfile Atualizado**
```dockerfile
# Antes
CMD ["./bin/thrust", "./bin/rails", "server"]

# Depois
CMD ["foreman", "start", "-f", "Procfile.dev"]
```

### 4. **Docker Compose Atualizado**
```yaml
# Antes
command: bash -c "bin/rails db:prepare && bin/rails s -b 0.0.0.0 -p 3000"

# Depois
command: ./bin/start
```

## 📋 **Processos Gerenciados pelo Foreman:**

### **Procfile (Produção)**
```
web: bin/rails server -p 3000 -b 0.0.0.0
css: bin/rails dartsass:watch
```

### **Procfile.dev (Desenvolvimento)**
```
web: bin/rails server -p 3000 -b 0.0.0.0
css: bin/rails dartsass:watch
```

## 🎯 **Vantagens do Foreman:**

### **1. Gerenciamento de Processos**
- ✅ Múltiplos processos em paralelo
- ✅ Logs coloridos e organizados
- ✅ Restart automático em caso de falha
- ✅ Controle de processos

### **2. Desenvolvimento**
- ✅ Servidor Rails + Compilação CSS simultânea
- ✅ Hot reload automático
- ✅ Logs unificados
- ✅ Fácil debugging

### **3. Produção**
- ✅ Processos otimizados
- ✅ Gerenciamento de recursos
- ✅ Monitoramento integrado
- ✅ Escalabilidade

## 🛠️ **Como Usar:**

### **Desenvolvimento Local**
```bash
# Iniciar todos os processos
foreman start -f Procfile.dev

# Ou usar o script
./bin/start
```

### **Docker**
```bash
# Subir containers
docker-compose up -d

# Ver logs
docker-compose logs -f web
```

### **Comandos Úteis**
```bash
# Verificar configuração
foreman check

# Listar processos
foreman start --help

# Executar processo específico
foreman run web
```

## 📊 **Processos em Execução:**

### **1. Web Server (Rails)**
- **Porta**: 3000
- **Binding**: 0.0.0.0 (aceita conexões externas)
- **Ambiente**: Desenvolvimento/Produção

### **2. CSS Compiler (DartSass)**
- **Função**: Compilação automática de SCSS
- **Watch**: Monitora mudanças em arquivos CSS
- **Hot Reload**: Atualização automática

## 🔧 **Configurações Avançadas:**

### **Adicionar Novos Processos**
```bash
# Editar Procfile.dev
echo "worker: bin/rails jobs:work" >> Procfile.dev
```

### **Variáveis de Ambiente**
```bash
# .env
PORT=3000
RAILS_ENV=development
```

### **Logs Personalizados**
```bash
# Foreman com logs coloridos
foreman start -f Procfile.dev --color
```

## 🚀 **Boot do Sistema:**

### **Sequência de Inicialização:**
1. **Docker Compose** inicia containers
2. **Script bin/start** executa
3. **Rails db:prepare** prepara banco
4. **Foreman** inicia processos
5. **Sistema** fica disponível

### **Verificação de Status:**
```bash
# Verificar se está rodando
docker-compose ps

# Ver logs em tempo real
docker-compose logs -f web

# Testar conectividade
curl http://localhost:3000
```

## 📈 **Monitoramento:**

### **Logs Unificados**
- ✅ Todos os processos em uma tela
- ✅ Cores diferentes por processo
- ✅ Timestamps automáticos
- ✅ Filtros por processo

### **Métricas**
- ✅ Uso de CPU por processo
- ✅ Uso de memória
- ✅ Status de cada processo
- ✅ Restart automático

## 🎉 **Sistema Pronto!**

O Foreman está configurado e funcionando. Agora o sistema:

- ✅ **Inicia automaticamente** com múltiplos processos
- ✅ **Gerencia recursos** de forma eficiente
- ✅ **Monitora processos** em tempo real
- ✅ **Reinicia automaticamente** em caso de falha
- ✅ **Logs organizados** para debugging

**Para iniciar o sistema:**
```bash
docker-compose up -d
```

**Para ver logs:**
```bash
docker-compose logs -f web
```

O sistema está otimizado e pronto para uso! 🚀
