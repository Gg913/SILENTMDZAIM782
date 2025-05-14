from flask import Flask, request, jsonify
from playwright.sync_api import sync_playwright
import base64

app = Flask(__name__)

def infracoes(placa: str):
    resultados = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()

        # Login
        page.goto('https://mpir.prf.gov.br/mpir/login')
        page.fill('input[name="username"]', '047.202.549-00')
        page.fill('input[name="password"]', 'Clnm*84262573*')
        page.click('#btnLogin')

        # Consulta
        page.goto('https://mpir.prf.gov.br/mpir/consultarImagem')
        page.fill('#placa', placa)
        page.click('.btn.btn-primary.btn-xs.fa.fa-filter')

        page.wait_for_selector('table tbody tr td a[data-id]', timeout=10000)

        ocorrencias = page.query_selector_all('table tbody tr td a[data-id]')
        for ocorrencia in ocorrencias:
            data_id = ocorrencia.get_attribute('data-id')
            if data_id:
                resp = context.request.get(f'https://mpir.prf.gov.br/mpir/getImagemInfo/{data_id}')
                if resp.status == 200:
                    json_data = resp.json()
                    path = json_data.get('path')
                    if path:
                        img_resp = context.request.get(f'https://mpir.prf.gov.br/mpir/{path}')
                        if img_resp.status == 200:
                            img_b64 = base64.b64encode(img_resp.body()).decode('utf-8')
                            json_data['imagemBase64'] = img_b64
                    resultados.append(json_data)

        browser.close()

    return resultados

@app.route('/infracoesPrf', methods=['GET'])
def router():
    placa = request.args.get('placa')
    if not placa:
        return jsonify({"erro": "a placa é obrigatório, animal"}), 400
    try:
        dados = infracoes(placa)
        return jsonify(dados)
    except Exception as e:
        return jsonify({"erro": f'se teve esse error entao e provavel que a placa nao foi encontrada, mais da um liga no log ai: {str(e)}. seila oque deu, mais se o tempo passou e o elemento nao foi achado entao e pq nao achou a placa, tome um 500 de statuscode ai '}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9000)
