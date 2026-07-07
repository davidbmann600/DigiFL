// Serverless proxy for Vercel: keeps the Anthropic API key server-side only.
// Set ANTHROPIC_API_KEY as an Environment Variable in the Vercel project settings
// (never commit it to the repo).
module.exports = async function handler(req, res) {
  if (req.method !== "POST") {
    res.status(405).json({ error: { message: "Method not allowed" } });
    return;
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    res.status(500).json({ error: { message: "Server misconfigured: ANTHROPIC_API_KEY is not set." } });
    return;
  }

  const { system, messages, max_tokens, beta } = req.body || {};
  if (!messages) {
    res.status(400).json({ error: { message: "Missing messages" } });
    return;
  }

  const headers = {
    "Content-Type": "application/json",
    "x-api-key": apiKey,
    "anthropic-version": "2023-06-01",
  };
  if (beta) headers["anthropic-beta"] = beta;

  try {
    const upstream = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers,
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: max_tokens || 600,
        ...(system ? { system } : {}),
        messages,
      }),
    });
    const data = await upstream.json();
    res.status(upstream.status).json(data);
  } catch (e) {
    res.status(502).json({ error: { message: e.message } });
  }
}
