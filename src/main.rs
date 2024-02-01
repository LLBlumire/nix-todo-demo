#[derive(Clone)]
struct AppState {
    db: sqlx::mysql::MySqlPool,
}

#[tokio::main]
async fn main() {
    let db = sqlx::mysql::MySqlPoolOptions::new().connect_lazy("mysql://root:password@localhost:3306/demodb").unwrap();
    let app = axum::Router::new()
        .route("/", axum::routing::get(home_page))
        .route("/todo", axum::routing::post(add_todo))
        .with_state(AppState { db });
    let listener = tokio::net::TcpListener::bind("0.0.0.0:0").await.unwrap();
    let local = listener.local_addr().unwrap();
    println!("Starting on http://localhost:{}", local.port());
    axum::serve(listener, app).await.unwrap();
}

#[derive(askama::Template)]
#[template(path = "base.html")]
struct Base<T: askama::Template> {
    content: T
}

#[derive(askama::Template)]
#[template(path = "home.html")]
struct HomePage {
    todos: Vec<Todo>
}

struct Todo {
    uuid: uuid::Uuid,
    body: String,
    created: time::PrimitiveDateTime,
}

#[axum_macros::debug_handler]
async fn home_page(axum::extract::State(AppState { db }): axum::extract::State<AppState>) -> Base<HomePage> {
    let todos = sqlx::query!("SELECT * FROM todos ORDER BY created").fetch_all(&db).await.unwrap().into_iter().map(|todo| Todo {
        uuid: todo.id.parse().unwrap(),
        body: todo.body.unwrap_or_default(),
        created: todo.created
    }).collect();
    Base {
        content: HomePage {
            todos
        }
    }
}

#[derive(serde::Deserialize)]
struct NewTodo {
    body: String
}

#[axum_macros::debug_handler]
async fn add_todo(axum::extract::State(AppState { db }): axum::extract::State<AppState>, axum::Form(NewTodo { body }): axum::Form<NewTodo>) -> axum::response::Redirect {
    let uuid = uuid::Uuid::new_v4().to_string();
    let now = time::OffsetDateTime::now_utc();
    let created = time::PrimitiveDateTime::new(now.date(), now.time());
    sqlx::query!("INSERT INTO todos (id, body, created) VALUES (?, ?, ?)", uuid, body, created).execute(&db).await.unwrap();
    axum::response::Redirect::to("/")
}
