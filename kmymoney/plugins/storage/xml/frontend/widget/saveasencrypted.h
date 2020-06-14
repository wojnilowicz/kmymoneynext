/*
 * Copyright 2020  Łukasz Wojniłowicz <lukasz.wojnilowicz@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef STORAGE_XML_FRONTEND_WIDGET_SAVEASENCRYPTED_H
#define STORAGE_XML_FRONTEND_WIDGET_SAVEASENCRYPTED_H

// ----------------------------------------------------------------------------
// KDE Includes

// ----------------------------------------------------------------------------
// QT Includes

// ----------------------------------------------------------------------------
// Project Includes

#include "frontend/saveasencrypted.h"

namespace Storage {
namespace Xml {
namespace Widget {

class SaveAsEncryptedPrivate;
class SaveAsEncrypted : public Xml::SaveAsEncrypted
{
  Q_OBJECT
  Q_DECLARE_PRIVATE(SaveAsEncrypted)

public:
  explicit SaveAsEncrypted(QObject *parent,
                           Backend *backend,
                           eType storageType,
                           const QUrl &startDirectory);
  ~SaveAsEncrypted() override final;

  QObject *uiPart() override final;
  void setStorageUrl(const QUrl &storageUrl) override final;
};

} // namespace Widget
} // namespace Xml
} // namespace Storage

#endif
