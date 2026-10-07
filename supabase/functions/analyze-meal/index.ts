const MODEL = "gemini-3.5-flash-lite";
const MAX_IMAGE_BYTES = 4 * 1024 * 1024;
const CATEGORIES = ["한식", "양식", "중식", "일식", "분식", "구내식당", "패스트푸드", "디저트/카페"];

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

const SYSTEM = `너는 음식 사진으로 칼로리를 계산하는 영양 분석가다. 사진에 보이는 음식을 식별해 JSON만 출력한다.

출력 형식:
{
  "recognized": true,
  "category": "한식" | "양식" | "중식" | "일식" | "분식" | "구내식당" | "패스트푸드" | "디저트/카페",
  "items": [
    {
      "question": "사용자가 고를 때 볼 짧은 질문. 후보가 하나면 빈 문자열",
      "choices": [
        { "label": "고를 때 보이는 짧은 말(재료나 메뉴 구분)", "name": "음식 이름", "portion": "사진 속 분량", "calories": 정수, "description": "재료와 영양 특징 한 문장" }
      ]
    }
  ],
  "estimated_servings_options": [[1], [2, 3]],
  "macro_feedback": "탄단지 균형과 바로 실천할 조언 2~3문장",
  "food_story": "대표 메뉴의 유래나 이야기 2~3문장"
}

규칙:
- 사진 속 개별 음식마다 items 하나를 만든다. 밥, 국, 반찬도 각각 나눈다.
- calories는 사진에 보이는 분량 전체 기준 정수 kcal다.
- 겉모습이 비슷해 메뉴나 주재료가 헷갈리면 choices에 후보를 2~4개 넣는다. 가능성 높은 순서로 둔다.
  예: 소스를 부은 튀김이면 question "어떤 튀김인가요?", choices 돼지고기 탕수육 / 닭고기 깐풍기 / 닭고기 유린기.
  예: 볶음밥이면 question "주재료가 무엇인가요?", choices 새우 / 돼지고기 / 김치.
  재료마다 칼로리가 다르면 그 차이를 calories에 반영한다.
- 분명한 음식은 choices를 하나만 두고 question은 빈 문자열이다.
- label은 8자 이내, question은 16자 이내로 쓴다.
- estimated_servings_options는 사진 속 양으로 추정한 인분 선택지다. 혼자 먹는 양이면 [[1]], 나눠 먹을 수 있는 양이면 [[1],[2,3]]처럼 준다.
- 음식이 아니거나 식별할 수 없으면 {"recognized": false, "items": []}만 출력한다.
- 의료 진단을 하지 않는다. 어조는 담백한 설명체(~해요).`;

function str(value: unknown, max: number): string {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

function kcal(value: unknown): number {
  const n = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(n)) return 0;
  return Math.min(5000, Math.max(0, Math.round(n)));
}

function clean(raw: Record<string, unknown>) {
  const items = (Array.isArray(raw.items) ? raw.items : [])
    .map((item) => {
      const rec = (item ?? {}) as Record<string, unknown>;
      const choices = (Array.isArray(rec.choices) ? rec.choices : [])
        .map((choice) => {
          const c = (choice ?? {}) as Record<string, unknown>;
          const name = str(c.name, 40);
          return {
            label: str(c.label, 20) || name,
            name,
            portion: str(c.portion, 40),
            calories: kcal(c.calories),
            description: str(c.description, 200),
          };
        })
        .filter((c) => c.name && c.calories > 0)
        .slice(0, 4);
      return { question: choices.length > 1 ? str(rec.question, 30) : "", choices };
    })
    .filter((item) => item.choices.length > 0)
    .slice(0, 8);

  const servings = (Array.isArray(raw.estimated_servings_options) ? raw.estimated_servings_options : [])
    .map((option) =>
      (Array.isArray(option) ? option : [option])
        .map((v) => Math.round(Number(v)))
        .filter((v) => Number.isFinite(v) && v >= 1 && v <= 20)
    )
    .filter((option) => option.length > 0)
    .slice(0, 4);
  if (!servings.some((option) => option.length === 1 && option[0] === 1)) servings.unshift([1]);

  const category = str(raw.category, 20);
  return {
    recognized: raw.recognized !== false && items.length > 0,
    category: CATEGORIES.includes(category) ? category : "한식",
    items,
    estimated_servings_options: servings,
    macro_feedback: str(raw.macro_feedback, 400),
    food_story: str(raw.food_story, 400),
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "POST만 받아요" }, 405);

  const key = Deno.env.get("GEMINI_API_KEY") ?? Deno.env.get("GEMINI_API_KEY_FREE") ?? "";
  if (!key) return json({ error: "GEMINI_API_KEY 시크릿이 없습니다" }, 500);

  let body: { image_base64?: string; mime_type?: string; meal_type?: string; client_time?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "요청 형식이 잘못되었습니다" }, 400);
  }
  const image = body.image_base64 ?? "";
  const mime = body.mime_type === "image/png" ? "image/png" : "image/jpeg";
  if (!image) return json({ error: "사진이 없습니다" }, 400);
  if (image.length * 0.75 > MAX_IMAGE_BYTES) return json({ error: "사진이 너무 큽니다" }, 413);

  const hint = `식사 구분: ${str(body.meal_type, 4) || "모름"}, 촬영 시각(한국): ${str(body.client_time, 30) || "모름"}`;
  try {
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${key}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: SYSTEM }] },
          contents: [{
            role: "user",
            parts: [{ inline_data: { mime_type: mime, data: image } }, { text: hint }],
          }],
          generationConfig: { temperature: 0.3, maxOutputTokens: 2048, responseMimeType: "application/json" },
        }),
      },
    );
    if (!response.ok) {
      const detail = await response.text();
      return json({ error: `Gemini 오류 ${response.status}: ${detail.slice(0, 200)}` }, 502);
    }
    const payload = await response.json();
    const text = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof text !== "string" || !text.trim()) return json({ error: "Gemini 응답이 비어 있습니다" }, 502);
    return json(clean(JSON.parse(text) as Record<string, unknown>));
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : "분석하지 못했습니다" }, 502);
  }
});
