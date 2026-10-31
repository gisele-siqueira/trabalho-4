
import http from 'k6/http';
import { check } from 'k6';

// Dez URLs diferentes para cada usuário virtual
const urls = [
  'https://www.python.org/',
  'https://www.python.org/about/',
  'https://www.python.org/downloads/',
  'https://www.python.org/doc/',
  'https://www.python.org/community/',
  'https://www.python.org/events/',
  'https://www.python.org/blogs/',
  'https://www.python.org/jobs/',
  'https://www.python.org/psf/',
  'https://www.python.org/success-stories/'
];

// Configuração do teste de desempenho da API Ruby
export const options = {
  scenarios: {
    teste_ruby: {
      executor: 'per-vu-iterations',
      vus: 10,
      iterations: 1,
      maxDuration: '5m'
    }
  },

  thresholds: {
    http_req_failed: ['rate<0.05']
  }
};

// Função executada por cada usuário virtual
export default function () {

  for (const url of urls) {

    // Endereço da API Ruby no Docker
    const endpoint =
      `http://host.docker.internal:5000/api/${url}`;

    // Realiza a requisição HTTP
    const resposta = http.get(endpoint, {
      timeout: '30s'
    });

    // Verifica se a resposta foi bem-sucedida
    check(resposta, {
      'HTTP 200': (r) => r.status === 200,

      'JSON valido': (r) => {
        try {
          return Array.isArray(r.json());
        } catch (e) {
          return false;
        }
      }
    });
  }
}



