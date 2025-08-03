export default {
  async fetch(request, env, ctx) {
    if (request.method === 'GET') {
      return new Response(`
        <!DOCTYPE html>
        <html>
          <head>
            <title>Monitoring Bot Worker</title>
            <style>
              body {
                background-color: #0f172a;
                color: #38bdf8;
                font-family: monospace;
                display: flex;
                align-items: center;
                justify-content: center;
                height: 100vh;
                margin: 0;
              }
              h1 {
                font-size: 2.5rem;
                text-align: center;
              }
            </style>
          </head>
          <body>
            <h1>Monitoring Bot Worker is running ... ✅</h1>
          </body>
        </html>
      `, {
        status: 200,
        headers: { "Content-Type": "text/html; charset=utf-8" }
      });
    }

    if (request.method !== 'POST') {
      return new Response("Only POST method is allowed", { status: 405 });
    }

    try {
      const { token, chat_id, text } = await request.json();

      if (!token || !chat_id || !text) {
        return new Response("Missing required fields", { status: 400 });
      }

      const telegram_url = `https://api.telegram.org/bot${token}/sendMessage`;
      const payload = {
        chat_id,
        text,
        parse_mode: "Markdown"
      };

      const tg_response = await fetch(telegram_url, {
        method: 'POST',
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      const tg_result = await tg_response.text();
      return new Response(tg_result, { status: tg_response.status });

    } catch (err) {
      return new Response("Error: " + err.toString(), { status: 500 });
    }
  }
}
