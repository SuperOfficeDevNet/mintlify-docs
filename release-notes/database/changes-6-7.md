---
uid: database-changes-6-to-7
title: Table changes from SuperOffice 6.3 to 7.0
description: Table changes from SuperOffice 6 to 7
author: SuperOffice Product and Engineering
version: 7
content_type: release-note
deployment: onsite
category: database
---

# Table changes from SuperOffice 6.3 to 7.0

## Renamed tables

| Table no | v.6 | v.7 |
|---|---|---|
| 37 | recordlink | [MergeMoveLog](../../en/database/tables/mergemovelog.md) |
| 115 | OptCat | [ReasonSold](../../en/database/tables/reasonsold.md) |
| 116 | OptCatGroupLink | [ReasonSoldGroupLink](../../en/database/tables/reasonsoldgrouplink.md) |
| 117 | OptCatHeadingLink | [ReasonSoldHeadingLink](../../en/database/tables/reasonsoldheadinglink.md) |
| 118 | OptType | [SaleTypeCat](../../en/database/tables/saletypecat.md) |
| 119 | OptTypeGroupLink | [SaleTypeCatGroupLink](../../en/database/tables/saletypecatgrouplink.md) |
| 120 | OptTypeHeadingLink | [SaleTypeCatHeadingLink](../../en/database/tables/saletypecatheadinglink.md) |
| 121 | OptState | [SaleStakeholder](../../en/database/tables/salestakeholder.md) |
| 122 | OptStateGroupLink | [StakeholderRole](../../en/database/tables/stakeholderrole.md) |
| 123 | OptStateHeadingLink | [StakeholderRoleGroupLink](../../en/database/tables/stakeholderrolegrouplink.md) |
| 124 | OptInt | [StakeholderRoleHeadingLink](../../en/database/tables/stakeholderroleheadinglink.md) |
| 125 | OptIntGroupLink | [SuggestedAppointment](../../en/database/tables/suggestedappointment.md) |
| 126 | OptIntHeadingLink | [SuggestedDocument](../../en/database/tables/suggesteddocument.md) |
| 149 | Opportunity | [SaleType](../../en/database/tables/saletype.md) |
| 150 | OptItem | [SaleTypeGroupLink](../../en/database/tables/saletypegrouplink.md) |
| 151 | OptPlan | [SaleTypeHeadingLink](../../en/database/tables/saletypeheadinglink.md) |
| 152 | OptPlanItem | [TabOrder](../../en/database/tables/taborder.md) |
| 154 | SelCriterion | [ReasonStalled](../../en/database/tables/reasonstalled.md) |
| 155 | SelOpChain | [ReasonStalledGroupLink](../../en/database/tables/reasonstalledgrouplink.md) |
| 156 | SelOp | [ReasonStalledHeadingLink](../../en/database/tables/reasonstalledheadinglink.md) |
| 160 | DocumentLink | [SaleTypeStageLink](../../en/database/tables/saletypestagelink.md) |
| 212 | TimeZone | [ModuleOwner](../../en/database/tables/moduleowner.md) |
| 213 | TimeZoneCountry | [ProjectTypeStatusLink](../../en/database/tables/projecttypestatuslink.md) |
| 237 | ModuleLicence | [ModuleLicense](../../en/database/tables/modulelicense.md) |
| 238 | LicenceAssocLink | [LicenseAssocLink](../../en/database/tables/licenseassoclink.md) |
| 239 | LicenceSatlLink | [LicenseSatlLink](../../en/database/tables/licensesatllink.md) |

## Obsolete database tables

| Table no | v.6 | v.7 |
|---|---|---|
| 25 | selectionTask | `obsolete_1` |
| 26 | selTaskChain | `obsolete_2` |
| 27 | PDALink | `obsolete_3` |
| 34 | TrgdbAssocLink | `obsolete_4` |
| 39 | AreaCatLink | `obsolete_9` |
| 47 | freetextsynonyms | `obsolete_5` |
| 127 | OptDec | `obsolete_6` |
| 128 | OptDecGroupLink | `obsolete_7` |
| 129 | OptDecHeadingLink | `obsolete_8` |

These are now single-field tables in the dictionary, but they are not physically created in the database. This keeps the table numbers unchanged.

## New tables for eJournal

| Table no | Name |
|---|---|
| 253 | [registry](../../en/database/tables/registry.md) |
| 254 | [session\_object](../../en/database/tables/session-object.md) |
| 255 | [config](../../en/database/tables/config.md) |
| 256 | [ticket\_attachment](../../en/database/tables/ticket-attachment.md) |
| 257 | [ej\_category](../../en/database/tables/ej-category.md) |
| 258 | [ej\_message](../../en/database/tables/ej-message.md) |
| 259 | [message\_header](../../en/database/tables/message-header.md) |
| 260 | [message\_customers](../../en/database/tables/message-customers.md) |
| 261 | [ticket\_status\_history](../../en/database/tables/ticket-status-history.md) |
| 262 | [ticket](../../en/database/tables/ticket.md) |
| 263 | [ticket\_status](../../en/database/tables/ticket-status.md) |
| 264 | [ticket\_customers](../../en/database/tables/ticket-customers.md) |
| 265 | [invoice](../../en/database/tables/invoice.md) |
| 266 | [invoice\_sum](../../en/database/tables/invoice-sum.md) |
| 267 | [ticket\_log](../../en/database/tables/ticket-log.md) |
| 268 | [ticket\_log\_change](../../en/database/tables/ticket-log-change.md) |
| 269 | [ticket\_log\_action](../../en/database/tables/ticket-log-action.md) |
| 270 | [category\_membership](../../en/database/tables/category-membership.md) |
| 271 | [mail\_in\_filter](../../en/database/tables/mail-in-filter.md) |
| 272 | [mail\_in\_uidl](../../en/database/tables/mail-in-uidl.md) |
| 273 | [mail\_alias](../../en/database/tables/mail-alias.md) |
| 274 | [ticket\_alert](../../en/database/tables/ticket-alert.md) |
| 275 | [ticket\_priority](../../en/database/tables/ticket-priority.md) |
| 276 | [reply\_template\_folder](../../en/database/tables/reply-template-folder.md) |
| 277 | [reply\_template](../../en/database/tables/reply-template.md) |
| 278 | [reply\_template\_attachment](../../en/database/tables/reply-template-attachment.md) |
| 279 | [reply\_template\_body](../../en/database/tables/reply-template-body.md) |
| 280 | [doc\_document](../../en/database/tables/doc-document.md) |
| 281 | [doc\_folder](../../en/database/tables/doc-folder.md) |
| 282 | [kb\_entry](../../en/database/tables/kb-entry.md) |
| 283 | [kb\_category](../../en/database/tables/kb-category.md) |
| 284 | [kb\_attachment](../../en/database/tables/kb-attachment.md) |
| 285 | [kb\_http\_link](../../en/database/tables/kb-http-link.md) |
| 286 | [kb\_group](../../en/database/tables/kb-group.md) |
| 287 | [kb\_group\_entry](../../en/database/tables/kb-group-entry.md) |
| 288 | [kb\_entry\_keyword](../../en/database/tables/kb-entry-keyword.md) |
| 289 | [kb\_entry\_comment](../../en/database/tables/kb-entry-comment.md) |
| 290 | [kb\_entry\_log](../../en/database/tables/kb-entry-log.md) |
| 291 | [kb\_category\_log](../../en/database/tables/kb-category-log.md) |
| 292 | [kb\_workflow](../../en/database/tables/kb-workflow.md) |
| 293 | [kb\_workflow\_access](../../en/database/tables/kb-workflow-access.md) |
| 294 | [kb\_solution\_finder](../../en/database/tables/kb-solution-finder.md) |
| 295 | [kb\_solution\_finder\_entry](../../en/database/tables/kb-solution-finder-entry.md) |
| 296 | [attachment](../../en/database/tables/attachment.md) |
| 297 | [login](../../en/database/tables/login.md) |
| 298 | [login\_customer](../../en/database/tables/login-customer.md) |
| 299 | [ejuser](../../en/database/tables/ejuser.md) |
| 300 | [timestamps](../../en/database/tables/timestamps.md) |
| 301 | [notify](../../en/database/tables/notify.md) |
| 302 | [help](../../en/database/tables/help.md) |
| 303 | [company\_domain](../../en/database/tables/company-domain.md) |
| 304 | [extra\_fields](../../en/database/tables/extra-fields.md) |
| 305 | [extra\_tables](../../en/database/tables/extra-tables.md) |
| 306 | [hierarchy](../../en/database/tables/hierarchy.md) |
| 307 | [extra\_menus](../../en/database/tables/extra-menus.md) |
| 308 | [extra\_tables\_result](../../en/database/tables/extra-tables-result.md) |
| 309 | [extra\_tables\_entry](../../en/database/tables/extra-tables-entry.md) |
| 310 | [ms\_filter](../../en/database/tables/ms-filter.md) |
| 311 | [ms\_filter\_mail](../../en/database/tables/ms-filter-mail.md) |
| 312 | [ms\_trashbin](../../en/database/tables/ms-trashbin.md) |
| 313 | [ms\_substitute](../../en/database/tables/ms-substitute.md) |
| 314 | [eab\_folder](../../en/database/tables/eab-folder.md) |
| 315 | [eab\_entry](../../en/database/tables/eab-entry.md) |
| 316 | [mail\_block](../../en/database/tables/mail-block.md) |
| 317 | [ext\_datasource](../../en/database/tables/ext-datasource.md) |
| 318 | [ext\_table](../../en/database/tables/ext-table.md) |
| 319 | [ext\_field](../../en/database/tables/ext-field.md) |
| 320 | [cust\_lang](../../en/database/tables/cust-lang.md) |
| 321 | [cust\_category](../../en/database/tables/cust-category.md) |
| 322 | [password\_rules](../../en/database/tables/password-rules.md) |
| 323 | [ej\_role](../../en/database/tables/ej-role.md) |
| 324 | [role\_member](../../en/database/tables/role-member.md) |
| 325 | [role\_category](../../en/database/tables/role-category.md) |
| 326 | [role\_element](../../en/database/tables/role-element.md) |
| 327 | [role\_workflow](../../en/database/tables/role-workflow.md) |
| 328 | [element\_profile](../../en/database/tables/element-profile.md) |
| 329 | [profile](../../en/database/tables/profile.md) |
| 330 | [chat\_topic](../../en/database/tables/chat-topic.md) |
| 331 | [chat\_topic\_user](../../en/database/tables/chat-topic-user.md) |
| 332 | [chat\_session](../../en/database/tables/chat-session.md) |
| 333 | [chat\_message](../../en/database/tables/chat-message.md) |
| 334 | [s\_shipment](../../en/database/tables/s-shipment.md) |
| 335 | [s\_message](../../en/database/tables/s-message.md) |
| 336 | [s\_link](../../en/database/tables/s-link.md) |
| 337 | [s\_link\_customer](../../en/database/tables/s-link-customer.md) |
| 338 | [s\_link\_customer\_statical](../../en/database/tables/s-link-customer-statical.md) |
| 339 | [s\_picture\_folder](../../en/database/tables/s-picture-folder.md) |
| 340 | [s\_picture\_entry](../../en/database/tables/s-picture-entry.md) |
| 341 | [s\_washing](../../en/database/tables/s-washing.md) |
| 342 | [s\_bounce\_shipment](../../en/database/tables/s-bounce-shipment.md) |
| 343 | [s\_washing\_list](../../en/database/tables/s-washing-list.md) |
| 344 | [s\_list](../../en/database/tables/s-list.md) |
| 345 | [s\_list\_element](../../en/database/tables/s-list-element.md) |
| 346 | [s\_list\_customer](../../en/database/tables/s-list-customer.md) |
| 347 | [s\_shipment\_addr](../../en/database/tables/s-shipment-addr.md) |
| 348 | [s\_list\_shipment](../../en/database/tables/s-list-shipment.md) |
| 349 | [s\_attachment](../../en/database/tables/s-attachment.md) |
| 350 | [s\_dyn\_criteria](../../en/database/tables/s-dyn-criteria.md) |
| 351 | [outbox](../../en/database/tables/outbox.md) |
| 352 | [inbox](../../en/database/tables/inbox.md) |
| 353 | [legal\_html\_tags](../../en/database/tables/legal-html-tags.md) |
| 354 | [kb\_entry\_words](../../en/database/tables/kb-entry-words.md) |
| 355 | [word\_relations](../../en/database/tables/word-relations.md) |
| 356 | [temporary\_words](../../en/database/tables/temporary-words.md) |
| 357 | [wsdl\_description](../../en/database/tables/wsdl-description.md) |
| 358 | [dictionary](../../en/database/tables/dictionary.md) |
| 359 | [dictionary\_base](../../en/database/tables/dictionary-base.md) |
| 360 | [invoice\_entry](../../en/database/tables/invoice-entry.md) |
| 361 | [invoice\_type](../../en/database/tables/invoice-type.md) |
| 362 | [soap\_access](../../en/database/tables/soap-access.md) |
| 363 | [hotlist](../../en/database/tables/hotlist.md) |
| 364 | [log\_events](../../en/database/tables/log-events.md) |
| 365 | [log\_debug](../../en/database/tables/log-debug.md) |
| 366 | [form\_keys](../../en/database/tables/form-keys.md) |
| 367 | [sms\_hysteria](../../en/database/tables/sms-hysteria.md) |
| 368 | [item\_config](../../en/database/tables/item-config.md) |
| 369 | [snapshot](../../en/database/tables/snapshot.md) |
| 370 | [screen\_definition](../../en/database/tables/screen-definition.md) |
| 371 | [screen\_definition\_action](../../en/database/tables/screen-definition-action.md) |
| 372 | [screen\_definition\_element](../../en/database/tables/screen-definition-element.md) |
| 373 | [screen\_definition\_hidden](../../en/database/tables/screen-definition-hidden.md) |
| 374 | [screen\_definition\_language](../../en/database/tables/screen-definition-language.md) |
| 375 | [screen\_chooser](../../en/database/tables/screen-chooser.md) |
| 376 | [scheduled\_task](../../en/database/tables/scheduled-task.md) |
| 377 | [ejscript](../../en/database/tables/ejscript.md) |
| 378 | [system\-script](../../en/database/tables/system-script.md) |
| 379 | [schedule](../../en/database/tables/schedule.md) |
| 380 | [locking](../../en/database/tables/locking.md) |
| 381 | [dbi\_agent](../../en/database/tables/dbi-agent.md) |
| 382 | [dbi\_agent\_field](../../en/database/tables/dbi-agent-field.md) |
| 383 | [dbi\_agent\-schedule](../../en/database/tables/dbi-agent-schedule.md) |
| 384 | [ejpackage](../../en/database/tables/ejpackage.md) |
| 385 | [ejpackage\_item](../../en/database/tables/ejpackage-item.md) |
| 386 | [message\_id](../../en/database/tables/message-id.md) |
| 387 | [ejscript\_debug](../../en/database/tables/ejscript-debug.md) |
| 388 | [sms](../../en/database/tables/sms.md) |
| 389 | [user\_candidate](../../en/database/tables/user-candidate.md) |
| 390 | [s\_smtp\_servers](../../en/database/tables/s-smtp-servers.md) |
| 391 | [ejselection](../../en/database/tables/ejselection.md) |
| 392 | [ejsel\_ejsel](../../en/database/tables/ejsel-ejsel.md) |
| 393 | [ejsel\_source\_idlist](../../en/database/tables/ejsel-source-idlist.md) |
| 394 | [ejsel\_source\-script](../../en/database/tables/ejsel-source-script.md) |
| 395 | [ejsel\_source\_xml](../../en/database/tables/ejsel-source-xml.md) |
| 396 | [static\_list\_ref](../../en/database/tables/static-list-ref.md) |
| 397 | [ejsel\_meta\_result](../../en/database/tables/ejsel-meta-result.md) |
| 398 | [ejsel\_result\_set](../../en/database/tables/ejsel-result-set.md) |
| 399 | [tree\_explorer\_entry](../../en/database/tables/tree-explorer-entry.md) |
| 400 | [tree\_explorer\_link](../../en/database/tables/tree-explorer-link.md) |
| 401 | [external\_document](../../en/database/tables/external-document.md) |
| 402 | [autosave](../../en/database/tables/autosave.md) |
| 403 | [user\_attribute](../../en/database/tables/user-attribute.md) |
| 404 | [notice\_frame](../../en/database/tables/notice-frame.md) |
| 405 | [s\_sent\_message](../../en/database/tables/s-sent-message.md) |
| 406 | [access\-script](../../en/database/tables/access-script.md) |
