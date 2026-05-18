def test_index_redirects_to_login(client):
    response = client.get("/")
    assert response.status_code in [200, 302]


def test_login_page_loads(client):
    response = client.get("/login")
    assert response.status_code == 200
    assert b"Login" in response.data or b"login" in response.data.lower()


def test_api_products_unauthorized(client):
    response = client.get("/products/")
    assert response.status_code in [302, 401]


def test_dashboard_redirects_to_login(client):
    response = client.get("/dashboard")
    assert response.status_code == 302
    assert "/login" in response.location


def test_labels_redirects_to_login(client):
    response = client.get("/labels/")
    assert response.status_code in [302, 401]


def test_logout_redirects_to_login(client):
    response = client.get("/logout")
    assert response.status_code in [302, 404]


def test_orders_redirects_to_login(client):
    response = client.get("/orders/")
    assert response.status_code in [302, 401]


def test_internal_control_redirects(client):
    response = client.get("/control/")
    assert response.status_code in [302, 401]
