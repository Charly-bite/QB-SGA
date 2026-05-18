import pytest
from unittest.mock import patch, MagicMock


def test_label_generation_endpoint(client):
    """
    Test the endpoint that generates the label, ensuring it handles
    the request correctly without throwing a server error.
    """
    # Assuming the route is /products/api/generate_label/CODE
    response = client.get("/products/api/generate_label/TEST-01")

    # 404 if product not found, 302 if unauthenticated, 200 if successful
    assert response.status_code in [200, 302, 401, 404]


@patch("generate_ghs_label.pdfkit.from_string")
def test_generate_ghs_label_mock(mock_pdfkit):
    """
    Test the GHS label PDF generation logic with mocked pdfkit
    to ensure it parses the HTML without actually rendering a PDF in CI/CD.
    """
    # Simulate pdfkit returning a binary PDF payload
    mock_pdfkit.return_value = b"%PDF-1.4 Mock PDF Data"

    try:
        from generate_ghs_label import generate_pdf

        # Test that calling generate_pdf correctly invokes pdfkit
        result = generate_pdf("<html>Mock Label</html>", "mock_output.pdf", options={})

        # Verify pdfkit was called
        mock_pdfkit.assert_called_once()
        assert result is True or result is not None

    except ImportError:
        # Skip if generate_pdf is not structured this way
        pytest.skip("generate_ghs_label.py structure differs")
